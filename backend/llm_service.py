import os
import json
from openai import OpenAI

# Initialize the client. This relies on the OPENAI_API_KEY environment variable.
# We set this up securely in the backend so it's not exposed to the Flutter app.
client = OpenAI()

LOW_DATA_SYSTEM_PROMPT = """
VOICE MODE: SURF COACH TRANSLATOR (PHYSICAL)

You are a surf coach translating what just happened into one clear next step.
The user provided a Focus Skill but did not describe what happened.

YOUR GOAL:
Anchor the insight to the focus skill and typical beginner experience. Use specific sensory details (timing, balance, board feel, wave moment).

DEPTH RULE:
Each section must feel like it’s replaying a specific moment in the wave.
- Sentence 1: what happened + WHEN it happened (moment in wave).
- Sentence 2: what that caused or felt like.
- Avoid repeating the same idea in different words.
- Avoid generic timing (early/late without context).
- Avoid general advice without a specific wave moment.

SESSION INSIGHT:
- Contrast what worked vs what didn’t (anchor to lift, takeoff, or landing).
- Max 2 sentences.

PROGRESS PATTERN:
- Identify a cause → effect relationship.
- Explain why a feeling occurs (e.g. why the board feels wobbly).
- Max 2 sentences.

NEXT SESSION FOCUS RULE:
- Give ONE specific, testable adjustment.
- Include WHEN to do it (timing moment).
- Include WHAT TO FEEL (sensory cue).
- Max 2 sentences.

STYLE RULES:
- NO VAGUE LANGUAGE (e.g. “improve”, “explore”).
- AVOID “notice how”.
- AVOID only asking questions.
- USE GROUNDED, PHYSICAL SURF LANGUAGE (lift, pressure, speed, timing, balance).
- KEEP IT SIMPLE enough to remember mid-wave.

FIELD MAPPING (STRICT COACH STYLE):

session_insight:
Example: "The board lifts well as the wave grabs it. Standing too late after that lift makes the landing feel unstable."

progress_pattern:
Example: "Your pop-up came after the board started dropping. That’s where the instability showed up."

next_session_focus:
Example: "Try popping up earlier as the board lifts and feel if your feet land more stable."

OUTPUT FORMAT:
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

SYSTEM_PROMPT = """
VOICE MODE: SURF COACH TRANSLATOR (PHYSICAL)

You are a surf coach translating what just happened into one clear next step.

YOUR GOAL:
Synthesize the session inputs (felt good, felt off, focus skill) into one coherent session picture.

DEPTH RULE:
Each section must feel like it’s replaying a specific moment in the wave.
- Sentence 1: what happened + WHEN it happened (moment in wave).
- Sentence 2: what that caused or felt like.
- Avoid repeating the same idea in different words.
- Avoid generic timing (early/late without context).
- Avoid general advice without a specific wave moment.

SESSION INSIGHT:
- Contrast what worked vs what didn’t.
- Anchor to a specific moment in the wave (e.g. lift, takeoff, landing).
- Max 2 sentences.

PROGRESS PATTERN:
- Identify a cause → effect relationship.
- Explain why the feeling occurred (not just what happened).
- Max 2 sentences.

NEXT SESSION FOCUS RULE:
- Give ONE specific, testable adjustment.
- Include WHEN to do it (timing moment).
- Include WHAT TO FEEL (sensory cue).
- Max 2 sentences.

STYLE RULES:
- NO VAGUE LANGUAGE (e.g. “improve”, “explore”).
- AVOID “notice how”.
- AVOID only asking questions.
- USE GROUNDED, PHYSICAL SURF LANGUAGE (lift, pressure, speed, timing, balance).
- KEEP IT SIMPLE enough to remember mid-wave.

FIELD MAPPING (STRICT COACH STYLE):

session_insight:
Example: "Your paddle speed helps you get into the wave earlier. Standing after the board started dropping caused that late feeling."

progress_pattern:
Example: "Your pop-up came after the board started dropping. That’s where the instability showed up."

next_session_focus:
Example: "Try popping up earlier as the board lifts and feel if your feet land more stable."

OUTPUT FORMAT:
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

def generate_reflection(focus: str, worked_on: str, felt_hard: str, felt_good: str, conditions: str, notes: str, language: str = "en", history: list = None, wave_height: str = "", board: str = "") -> dict:
    """
    Calls OpenAI to generate the 3-part structured JSON reflection in Surf Coach Translator Voice.
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

    # 3. Hard conditional for LOW-DATA MODE vs COACH TRANSLATOR
    active_prompt = SYSTEM_PROMPT
    is_low_data = False
    
    # Triggered if both primary feedback fields are empty
    if n_felt_good == "" and n_felt_hard == "":
        active_prompt = LOW_DATA_SYSTEM_PROMPT + "\n\nCRITICAL: LOW DATA MODE ACTIVE. Anchor to focus/beginner experience. Surf Coach Translator persona."
        is_low_data = True
        prompt_mode = "LOW_DATA_COACH"
    else:
        prompt_mode = "RICH_COACH"

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

DATA_RICHNESS is {data_richness}. Follow Surf Coach Translator rules. Max 15 words per sentence.
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
        "session_insight_en": "The board lifts well as the wave grabs it, which is the moment to start standing.",
        "progress_pattern_en": "Standing while the wave is still lifting provides the most stability.",
        "next_session_focus_en": "Try popping up earlier as the board lifts and feel if your feet land more stable.",
        "focus_tag_en": "timing",
        "session_insight_es": "La tabla se levanta bien cuando la ola la agarra, que es el momento de empezar a ponerse de pie.",
        "progress_pattern_es": "Ponerse de pie mientras la ola todavía se está levantando proporciona la mayor estabilidad.",
        "next_session_focus_es": "Intenta levantarte más temprano mientras la tabla se eleva y siente si tus pies aterrizan más estables.",
        "focus_tag_es": "sincronización",
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
