import os
import json
from openai import OpenAI

# Initialize the client. This relies on the OPENAI_API_KEY environment variable.
# We set this up securely in the backend so it's not exposed to the Flutter app.
client = OpenAI()

LOW_DATA_SYSTEM_PROMPT = """
VOICE MODE: INTERNAL SURF THOUGHT (AWARENESS-BASED)

You are not a surf coach. You are a neutral observer helping the surfer reflect.
The user provided a Focus Skill but did not describe what happened in their reflection.

YOUR GOAL:
Write like a surfer thinking back after a session. Help them become more aware of what they are noticing in the water. 

STRICT RULES:
- REMOVE SYSTEM-LIKE LANGUAGE. Do NOT use: "since you chose", "based on your selection", "given your focus skill", "timing can be hard", "this could be something to pay attention to".
- START NATURALLY. Start insights like a thought or observation, not a formal response.
- DO NOT ASSUME ANYTHING. No cause/effect. No diagnosing technique.
- DO NOT USE AUTHORITATIVE LANGUAGE. Avoid: "you are", "this is because", "this leads to", "a pattern is emerging".
- DO NOT state what is happening as a fact.
- USE OBSERVATIONAL PHRASING ONLY: "you might notice...", "one thing to watch...", "it could be interesting to see if...".
- MAKE IT FEEL LIKE AN INTERNAL THOUGHT. Something they might actually remember while paddling into a wave. No structured or instructional phrasing.

FIELD MAPPING (STRICT JOURNAL STYLE):

session_insight:
A moment to notice (sensory or timing-based). 
Example: "Next time, it might be interesting to notice the sensation of the board lifting just before you stand up."

progress_pattern:
A very short continuation of awareness. No analytical language.
Example: "The exact moment the wave grabs the board is a subtle feeling to track."

next_session_focus:
ONE simple experiment that feels easy to try in the water.
Example: "Maybe try popping up a split-second earlier and see if the board feels more settled."

OUTPUT FORMAT:
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

SYSTEM_PROMPT = """
VOICE MODE: INTERNAL SURF THOUGHT (AWARENESS-BASED)

You are not a surf coach. You are a neutral reflection tool helping the surfer notice patterns in their own session.

YOUR GOAL:
Write like a surfer thinking back after a session. Help them become more aware of what they are feeling and noticing in the water. 

STRICT RULES:
- REMOVE SYSTEM-LIKE LANGUAGE. Do NOT use: "since you chose", "based on your selection", "given your focus skill", "timing can be hard", "this could be something to pay attention to".
- START NATURALLY. Start insights like a thought or observation, not a formal response.
- DO NOT ASSUME ANYTHING that was not explicitly provided. No cause/effect unless the user said it.
- DO NOT USE AUTHORITATIVE LANGUAGE. Avoid: "you are", "this is because", "this leads to", "a pattern is emerging".
- USE OBSERVATIONAL LANGUAGE ONLY: "you might notice...", "one thing to watch...", "it could be interesting to see if...", "you mentioned...".
- USE ONLY PROVIDED REFLECTIONS. Reference them directly. Gently connect ideas, NOT conclusions.
- PROGRESS PATTERN MUST EARN ITS PLACE. Only include a connection if there is a REAL link in the reflections. Otherwise, keep it very short and awareness-focused.
- MAKE IT FEEL LIKE AN INTERNAL THOUGHT. Something they might actually remember while paddling into a wave. No structured or instructional phrasing. No "lessons."
- ONE CLEAR IDEA PER SECTION. Avoid repetition across sections.

FIELD MAPPING:

session_insight:
A moment to notice (sensory or timing-based). Grounded in user input.
Example: "Thinking back to that faster feeling you mentioned—it could be interesting to notice how that connects to the timing of the first paddle stroke."

progress_pattern:
A connection ONLY if reflections support it. Otherwise, a brief awareness cue.
Example: "The link between where your feet land and how the board tracks forward is a useful one to keep tracking."

next_session_focus:
ONE simple experiment that feels easy to try in the water.
Example: "Next session, maybe notice if staying low for one extra second during the pop-up changes how the board feels."

TONE:
Calm. Neutral. Observational. Non-judgmental. Internal thought.

OUTPUT FORMAT:
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

def generate_reflection(focus: str, worked_on: str, felt_hard: str, felt_good: str, conditions: str, notes: str, language: str = "en", history: list = None, wave_height: str = "", board: str = "") -> dict:
    """
    Calls OpenAI to generate the 3-part structured JSON reflection in Internal Thought Voice.
    """
    if not os.getenv("OPENAI_API_KEY"):
        raise ValueError("OPENAI_API_KEY environment variable is missing.")

    # 1. Normalize inputs (handle "null", None, whitespace)
    def normalize(v):
        if v is None: return ""
        s = str(v).strip()
        if s.lower() in ["", "null", "none", "undefined"]: return ""
        return s

    n_felt_good = normalize(felt_good)
    n_felt_hard = normalize(felt_hard)
    n_focus = normalize(focus)

    # 2. Compute data richness
    reflection_fields = [n_felt_good, n_felt_hard, normalize(worked_on), normalize(notes), normalize(conditions)]
    filled = sum(1 for f in reflection_fields if f != "")
    
    print(f"\n[DataAudit] reflectionGood normalized: {n_felt_good!r}")
    print(f"[DataAudit] reflectionOff normalized: {n_felt_hard!r}")
    print(f"[DataAudit] focusSkill: {n_focus!r}")
    
    if filled == 0:
        data_richness = "THIN"
    elif filled <= 2:
        data_richness = "MODERATE"
    else:
        data_richness = "RICH"

    # 3. Hard conditional for LOW-DATA MODE vs INTERNAL THOUGHT
    active_prompt = SYSTEM_PROMPT
    is_low_data = False
    
    # Triggered if both primary feedback fields are empty
    if n_felt_good == "" and n_felt_hard == "":
        active_prompt = LOW_DATA_SYSTEM_PROMPT + "\n\nCRITICAL: LOW DATA MODE ACTIVE. No system language. Internal thought only."
        is_low_data = True
        prompt_mode = "LOW_DATA_THOUGHT"
    else:
        prompt_mode = "RICH_THOUGHT"

    print(f"[DataAudit] isLowDataMode: {is_low_data}")
    print(f"[DataAudit] PROMPT_MODE: {prompt_mode}")

    # Format history for context if available
    history_text = ""
    if history:
        history_text = "RECENT SESSION HISTORY:\n" + "\n".join([
            f"- Session: Focus: {s.get('sessionFocus', 'N/A')}, Outcome: {s.get('aiNextFocusEn', 'N/A')}"
            for s in history[:3]
        ]) + "\n\n"
    
    print(f"\n[DataAudit] history_text sent to LLM:\n{history_text}")

    user_content = f"""
{history_text}DATA_RICHNESS: {data_richness}

Session details:
- Focus area: {n_focus or 'not specified'}
- Wave height: {normalize(wave_height) or 'not specified'}
- Board: {normalize(board) or 'not specified'}
- Conditions: {normalize(conditions) or '[not provided]'}
- What felt good: {n_felt_good or '[not provided]'}
- What felt tricky: {n_felt_hard or '[not provided]'}
- What they were working on: {normalize(worked_on) or '[not provided]'}
- Notes: {normalize(notes) or '[not provided]'}

DATA_RICHNESS is {data_richness}. Write like an internal thought. No system language. No diagnose. Use only provided facts.
Write the response now. Follow all tone and structure rules.
    """.strip()

    import hashlib
    prompt_hash = hashlib.md5(active_prompt.encode()).hexdigest()[:8]

    print("\n" + "="*60)
    print("SMART SURF — PROMPT SENT TO OPENAI")
    print("="*60)
    print(f"MODEL: gpt-4o-mini | TEMPERATURE: 0.4 | PROMPT HASH: {prompt_hash} | MODE: {prompt_mode}")
    print("-"*60)
    print("ACTIVE SYSTEM PROMPT:\n", active_prompt.strip())
    print("-"*60)
    print("USER MESSAGE:\n", user_content)
    print("="*60 + "\n")

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": active_prompt.strip()},
            {"role": "user", "content": user_content}
        ],
        response_format={"type": "json_object"},
        temperature=0.4,
        max_tokens=1000
    )

    FALLBACK = {
        "session_insight_en": "Thinking back, it might be interesting to notice how the board feels right at the moment of takeoff.",
        "progress_pattern_en": "Developing awareness of that takeoff rhythm is a good one to track.",
        "next_session_focus_en": "Next time, maybe notice the exact moment you feel the wave grab the board.",
        "focus_tag_en": "awareness",
        "session_insight_es": "Pensando en retrospectiva, podría ser interesante notar cómo se siente la tabla justo en el momento del despegue.",
        "progress_pattern_es": "Desarrollar conciencia de ese ritmo de despegue es algo bueno para seguir.",
        "next_session_focus_es": "La próxima vez, tal vez nota el momento exacto en que sientes que la ola agarra la tabla.",
        "focus_tag_es": "conciencia",
    }

    raw_content = ""
    try:
        raw_content = response.choices[0].message.content
        print(f"\nRAW LLM RESPONSE:\n{raw_content}\n")

        # Layer 1: direct parse (happy path — model returned clean JSON)
        try:
            parsed = json.loads(raw_content)
            print(f"[DataAudit] PARSED_RESPONSE (layer 1): {json.dumps(parsed, indent=2)}")
            return parsed
        except json.JSONDecodeError:
            pass

        # Layer 2: extract first {...} block (handles extra prose around JSON)
        import re
        match = re.search(r'\{.*\}', raw_content, re.DOTALL)
        if match:
            try:
                parsed = json.loads(match.group(0))
                print(f"[DataAudit] PARSED_RESPONSE (layer 2): {json.dumps(parsed, indent=2)}")
                return parsed
            except json.JSONDecodeError:
                pass

        # Layer 3: fallback
        print(f"PARSE FAILED — returning fallback. Raw output was:\n{raw_content}")
        return FALLBACK

    except Exception as e:
        print(f"PARSE FAILED — unexpected error: {e}. Raw content: {raw_content!r}")
        return FALLBACK
