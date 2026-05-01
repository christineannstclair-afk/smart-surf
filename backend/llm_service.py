import os
import json
from openai import OpenAI

# Initialize the client. This relies on the OPENAI_API_KEY environment variable.
# We set this up securely in the backend so it's not exposed to the Flutter app.
client = OpenAI()

LOW_DATA_SYSTEM_PROMPT = """
VOICE MODE: SURF JOURNAL (AWARENESS-BASED)

You are not a surf coach. You are a neutral observer helping the surfer reflect on their session.
The user provided a Focus Skill but did not describe what happened in their reflection.

YOUR GOAL:
Help the surfer become more aware of what they are noticing in the water. Provide a calm awareness cue and a simple experiment based ONLY on the chosen Focus Skill.

STRICT RULES:
- DO NOT ASSUME ANYTHING. No cause/effect. No diagnosing technique.
- DO NOT USE AUTHORITATIVE LANGUAGE. Avoid: "you are", "this is because", "this leads to", "a pattern is emerging".
- DO NOT state what is happening as a fact (e.g., no "the wave is flattening", "the board is sinking").
- USE OBSERVATIONAL PHRASING ONLY: "you might notice...", "one thing to watch...", "it could be interesting to pay attention to...".
- STAY SIMPLE AND SPECIFIC. Write like a surfer reflecting after a session.
- ONE CLEAR IDEA PER SECTION. Avoid repetition across sections.

FIELD MAPPING (STRICT JOURNAL STYLE):

session_insight:
A simple observation or thing to notice based on the Focus Skill. No assumptions.
Example: "Since you chose pop-up timing, one thing to notice next session is the sensation of the board lifting just before you stand up."

progress_pattern:
A neutral awareness cue. Do not use the word "pattern".
Example: "Noticing the exact moment you feel the wave's power grab the board is something to pay attention to."

next_session_focus:
ONE small experiment or thing to try. Must feel actionable and easy to remember in the water.
Example: "Next session, you might observe whether the board feels more stable if you pop up a split-second earlier than usual."

OUTPUT FORMAT:
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

SYSTEM_PROMPT = """
VOICE MODE: SURF JOURNAL (AWARENESS-BASED)

You are not a surf coach. You do NOT diagnose, judge, or correct the surfer.
You are a neutral reflection tool helping the surfer notice patterns in their own session.

YOUR GOAL:
Help the surfer become more aware of what they are feeling and noticing in the water. Connect their observations gently without drawing conclusions.

STRICT RULES:
- DO NOT ASSUME ANYTHING that was not explicitly provided. No cause/effect unless the user said it.
- DO NOT USE AUTHORITATIVE LANGUAGE. Avoid: "you are", "this is because", "this leads to", "a pattern is emerging".
- USE OBSERVATIONAL LANGUAGE ONLY: "you might notice...", "one thing to watch...", "it could be interesting to pay attention to...", "you mentioned...".
- USE ONLY PROVIDED REFLECTIONS. Reference them directly. Gently connect ideas, NOT conclusions.
- IF DATA IS LIMITED: Stay general but useful. Focus on a single moment, feeling, or cue.
- MAKE IT FEEL HUMAN + MEMORABLE. Write like a surfer reflecting. The surfer should be able to remember this in the water.
- ONE CLEAR IDEA PER SECTION. Avoid repetition across sections.

FIELD MAPPING:

session_insight:
A simple observation or thing to notice. Grounded in user input. No assumptions.
Example: "You mentioned the board felt faster today — you might notice how that sensation connects to the timing of your first paddle stroke."

progress_pattern:
ONLY include if reflections exist. Light connection between what they felt. No "pattern" language.
Example: "Based on what you noticed at takeoff, you might observe a link between where your feet land and how the board tracks forward."

next_session_focus:
ONE small experiment or thing to try. Must feel actionable and easy to remember in the water.
Example: "Next session, notice whether the board feels more settled if you stay low for one extra second during the pop-up."

TONE:
Calm. Neutral. Observational. Non-judgmental. Feels like a surfer journaling, not a coach correcting.

OUTPUT FORMAT:
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

def generate_reflection(focus: str, worked_on: str, felt_hard: str, felt_good: str, conditions: str, notes: str, language: str = "en", history: list = None, wave_height: str = "", board: str = "") -> dict:
    """
    Calls OpenAI to generate the 3-part structured JSON reflection in Journal Voice.
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

    # 3. Hard conditional for LOW-DATA MODE vs JOURNAL (Now Journal vs Journal-Rich)
    active_prompt = SYSTEM_PROMPT
    is_low_data = False
    
    # Triggered if both primary feedback fields are empty
    if n_felt_good == "" and n_felt_hard == "":
        active_prompt = LOW_DATA_SYSTEM_PROMPT + "\n\nCRITICAL: LOW DATA MODE ACTIVE. Do not diagnose."
        is_low_data = True
        prompt_mode = "LOW_DATA_JOURNAL"
    else:
        prompt_mode = "RICH_JOURNAL"

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

DATA_RICHNESS is {data_richness}. Stay purely observational. Do not diagnose or infer causes. Use only provided facts.
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
        "session_insight_en": "One thing to notice next session is how the board feels at the moment of takeoff.",
        "progress_pattern_en": "You're building awareness of your session rhythm.",
        "next_session_focus_en": "Next time, notice the exact moment you feel the wave grab the board.",
        "focus_tag_en": "awareness",
        "session_insight_es": "Una cosa a notar en la próxima sesión es cómo se siente la tabla en el momento del despegue.",
        "progress_pattern_es": "Estás desarrollando conciencia del ritmo de tu sesión.",
        "next_session_focus_es": "La próxima vez, nota el momento exacto en que sientes que la ola agarra la tabla.",
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
