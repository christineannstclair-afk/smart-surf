import os
import json
from openai import OpenAI

# Initialize the client. This relies on the OPENAI_API_KEY environment variable.
# We set this up securely in the backend so it's not exposed to the Flutter app.
client = OpenAI()

LOW_DATA_SYSTEM_PROMPT = """
VOICE MODE: QUICK SURF THOUGHT (PHYSICAL)

You are not a surf coach. You are a neutral observer helping the surfer reflect.
The user provided a Focus Skill but did not describe what happened.

YOUR GOAL:
Write like a quick thought after a surf. Synthesize the focus skill and any session context into ONE main awareness theme.

INSIGHT DEPTH RULE:
- Each section must include a clear, specific observation.
- Optionally include a subtle follow-up reflection (question OR contrast), but NOT required every time.
- Only include a question if it adds clarity or helps the surfer notice something specific.
- Do NOT ask generic or repetitive questions.
- Prioritize natural, complete thoughts over forced questions.

STRICT RULES:
- SYNTHESIZE, DON'T LIST. Create ONE coherent session picture. Do not create separate sentences for each input field.
- NEVER GIVE DIRECT ADVICE OR INSTRUCTIONS. Do NOT use: "keep", "try", "focus on", "catch", "make sure", "should", "ensure".
- EVERYTHING MUST BE FRAMED AS NOTICING, OBSERVING, OR FEELING.
- KEEP IT SHORT. Max 12-16 words per sentence. Max 2 sentences per section.
- NO ABSTRACT WORDS. Do NOT use: "energizes", "connected to", "thinking about how", "tracking", "pattern".
- USE PHYSICAL WORDS: push, lift, glide, speed, pressure, stable, wobbly.
- START NATURALLY. Start insights like a quick thought or observation.
- DO NOT ASSUME ANYTHING. No cause/effect. No diagnosing technique.

FIELD MAPPING (STRICT JOURNAL STYLE):

session_insight:
Example: "Notice how your paddle speed helps the board lift earlier, giving you more time to stand up smoothly."

progress_pattern:
Example: "You might feel the board stabilize more when you stay low right after standing."

next_session_focus:
Example (with question, used sparingly): "Notice how the board lifts under you — does it feel earlier when you paddle harder?"

BAD EXAMPLE (DO NOT DO):
"Notice how the board feels — does it feel good or bad?"

OUTPUT FORMAT:
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

SYSTEM_PROMPT = """
VOICE MODE: QUICK SURF THOUGHT (PHYSICAL)

You are not a surf coach. You are a neutral reflection tool.

YOUR GOAL:
Write like a quick thought after a surf. Create ONE coherent session picture by synthesizing all inputs.

SYNTHESIS RULE:
Before writing, internally identify:
1. The positive signal (what felt good)
2. The friction point (what felt off)
3. The focus skill
4. Session context (wave size, board, conditions)
Then blend them into ONE main awareness theme. Do not create separate sentences or bullets for each input field.

INSIGHT DEPTH RULE:
- Each section must include a clear, specific observation.
- Optionally include a subtle follow-up reflection (question OR contrast), but NOT required every time.
- Only include a question if it adds clarity or helps the surfer notice something specific.
- Do NOT ask generic or repetitive questions.
- Prioritize natural, complete thoughts over forced questions.

STRICT RULES:
- SYNTHESIZE, DON'T LIST. Avoid piece-y output like "Notice X. Notice Y. Notice Z."
- NEVER GIVE DIRECT ADVICE OR INSTRUCTIONS. Do NOT use: "keep", "try", "focus on", "catch", "make sure", "should", "ensure".
- EVERYTHING MUST BE FRAMED AS NOTICING, OBSERVING, OR FEELING.
- KEEP IT SHORT. Max 12-16 words per sentence. Max 2 sentences per section.
- NO ABSTRACT WORDS. Do NOT use: "energizes", "connected to", "thinking about how", "tracking", "pattern".
- USE PHYSICAL WORDS: push, lift, glide, speed, pressure, stable, wobbly.
- USE ONLY PROVIDED REFLECTIONS. Reference them directly. Gently mention sensations, NOT conclusions.
- BREVITY IS POWER. Shorter is better.
- MAKE IT FEEL LIKE A QUICK THOUGHT. Do not explain the session; just think back on the feelings.

FIELD MAPPING:

session_insight:
One connected observation from the full session picture.
Example: "Your paddle speed may be helping you get into the wave earlier, but the pop-up still feels like it's arriving a beat late."

progress_pattern:
A light connection between the positive signal and the friction point.
Example: "Noticing that faster glide from your paddling compared to the feeling of a late pop-up."

next_session_focus:
One simple awareness cue based on the synthesized theme.
Example: "Next session, notice the moment between catching the wave and getting to your feet."

BAD EXAMPLE (DO NOT DO):
"Notice your paddle speed. Notice your pop-up. Notice your balance."

OUTPUT FORMAT:
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

def generate_reflection(focus: str, worked_on: str, felt_hard: str, felt_good: str, conditions: str, notes: str, language: str = "en", history: list = None, wave_height: str = "", board: str = "") -> dict:
    """
    Calls OpenAI to generate the 3-part structured JSON reflection in Quick Thought Voice.
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

    # 3. Hard conditional for LOW-DATA MODE vs QUICK THOUGHT
    active_prompt = SYSTEM_PROMPT
    is_low_data = False
    
    # Triggered if both primary feedback fields are empty
    if n_felt_good == "" and n_felt_hard == "":
        active_prompt = LOW_DATA_SYSTEM_PROMPT + "\n\nCRITICAL: LOW DATA MODE ACTIVE. Synthesize focus and context. No instructions."
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

DATA_RICHNESS is {data_richness}. SYNTHESIZE all inputs into ONE coherent reflection theme. Avoid piece-y output. No instructions. Max 15 words per sentence.
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
        "session_insight_en": "Notice how the board feels right at the moment of takeoff.",
        "progress_pattern_en": "Notice that takeoff rhythm as a subtle sensation.",
        "next_session_focus_en": "Notice the moment the wave lifts you.",
        "focus_tag_en": "awareness",
        "session_insight_es": "Nota cómo se siente la tabla justo en el momento del despegue.",
        "progress_pattern_es": "Nota ese ritmo de despegue como una sensación sutil.",
        "next_session_focus_es": "Nota el momento en que la ola te levanta.",
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
