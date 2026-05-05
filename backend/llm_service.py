import os
import json
from openai import OpenAI

# Initialize the client. This relies on the OPENAI_API_KEY environment variable.
# We set this up securely in the backend so it's not exposed to the Flutter app.
client = OpenAI()

LOW_DATA_SYSTEM_PROMPT = """
VOICE MODE: SURF JOURNAL REFLECTION (HUMAN)

You are a thoughtful surf journal reflection tool. You are NOT an AI coach.
The user provided a Focus Skill but did not describe what happened.

YOUR GOAL:
With minimal input, keep the insight general and awareness-based. Help the surfer reflect on their focus skill.

STRICT RULES:
- DO NOT HALLUCINATE: Do not invent what happened. Do not say the board dropped, the wave steepened, or balance was lost unless the user provided that.
- TONE: Calm, useful, beginner-friendly, non-judgmental. Sound human and honest.
- NEXT SESSION FOCUS: Use gentle phrasing like "Next session, pay attention to..." or "One thing to bring into the next session is...". Avoid bossy commands.
- BREVITY: 1–2 sentences per section. Do NOT force a second sentence if one strong sentence is better.
- SYNTHESIZE: Use the focus skill and session context to create a connected theme.

FIELD MAPPING:

session_insight:
Example: "With pop-up timing as your focus, the main thing to build awareness around is the moment between catching the wave and getting to your feet."

progress_pattern:
Example: "There is not enough reflection detail yet to identify a pattern, but timing is something that becomes easier to feel as you compare sessions."

next_session_focus:
Example: "Next session, pay attention to when the board first starts to glide and how ready your body feels to stand."

OUTPUT FORMAT:
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

SYSTEM_PROMPT = """
VOICE MODE: SURF JOURNAL REFLECTION (HUMAN)

You are a thoughtful surf journal reflection tool. You are NOT an AI coach.
Smart Surf is a journal that helps surfers reflect on what they felt, notice patterns, and choose one thing to pay attention to next session.

YOUR GOAL:
Synthesize the full session picture (focus skill, what felt good, what felt off, conditions, wave size, board) into one connected reflection theme.

STRICT RULES:
- RESTORE NATURAL HUMAN VOICE: Sound like a thoughtful surf reflection, not a technical diagnosis. "Here’s what your session seems to be pointing toward."
- DIRECT INPUT FIRST: If the user says "paddling felt stronger" or "felt late popping up", reflect those exact ideas back in a useful way.
- DO NOT HALLUCINATE: If the surfer gives no reflection details, do NOT invent what happened. Do not force cause/effect if there is not enough evidence.
- SYNTHESIZE, DON'T LIST: Do not respond to each field separately. Create one connected reflection theme.
- NEXT SESSION FOCUS: Use practical and memorable phrasing like "Next session, try noticing...", "See if...", or "Try noticing...". Avoid bossy commands like "Pop up immediately".
- TONE: Calm, useful, beginner-friendly, non-judgmental. Do not sound like a textbook or a coach scolding.
- BREVITY: 1–2 sentences per section. Do NOT force a second sentence if one strong sentence is better.

FIELD MAPPING:

session_insight:
Example: "Your paddling is starting to get you into waves with more confidence, but your pop-up still feels a beat behind. That gap between catching the wave and getting to your feet is the moment to pay attention to."

progress_pattern:
Example: "There may be a pattern forming where your entry into the wave is improving before your timing on the stand-up has caught up. That’s a useful place to focus because it connects speed, timing, and stability."

next_session_focus:
Example: "Next session, try noticing the first moment the board starts to glide. See if starting your pop-up a little closer to that moment feels more stable."

OUTPUT FORMAT:
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

def generate_reflection(focus: str, worked_on: str, felt_hard: str, felt_good: str, conditions: str, notes: str, language: str = "en", history: list = None, wave_height: str = "", board: str = "") -> dict:
    """
    Calls OpenAI to generate the 3-part structured JSON reflection in Surf Journal Reflection Voice.
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

    # 3. Hard conditional for LOW-DATA MODE vs JOURNAL REFLECTION
    active_prompt = SYSTEM_PROMPT
    is_low_data = False
    
    # Triggered if both primary feedback fields are empty
    if n_felt_good == "" and n_felt_hard == "":
        active_prompt = LOW_DATA_SYSTEM_PROMPT + "\n\nCRITICAL: LOW DATA MODE ACTIVE. Reflect on focus/beginner experience. Human Journal persona."
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

DATA_RICHNESS is {data_richness}. Follow Surf Journal Reflection rules. Restore natural human voice. No coaching.
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
        "session_insight_en": "Reflecting on your takeoff moment is a great way to build awareness.",
        "progress_pattern_en": "Timing often feels different from session to session as you learn the wave's rhythm.",
        "next_session_focus_en": "Next session, try noticing the moment the board starts its forward glide.",
        "focus_tag_en": "awareness",
        "session_insight_es": "Reflexionar sobre el momento del despegue es una excelente manera de desarrollar la conciencia.",
        "progress_pattern_es": "La sincronización a menudo se siente diferente de una sesión a otra a medida que aprendes el ritmo de la ola.",
        "next_session_focus_es": "En la próxima sesión, intenta notar el momento en que la tabla comienza su deslizamiento hacia adelante.",
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
