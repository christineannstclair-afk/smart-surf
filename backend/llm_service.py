import os
import json
from openai import OpenAI

# Initialize the client. This relies on the OPENAI_API_KEY environment variable.
# We set this up securely in the backend so it's not exposed to the Flutter app.
client = OpenAI()

LOW_DATA_SYSTEM_PROMPT = """
You are a surf coach reviewing a session with ZERO reflection data.
The user provided a Focus Skill but did not describe what happened.

YOUR GOAL:
Provide a helpful awareness cue and a simple experiment based ONLY on the chosen Focus Skill.

STRICT RULES:
- Do NOT diagnose. You have no evidence.
- Do NOT say "it seems like", "I noticed", or "the pop-up is occurring".
- Do NOT mention falling, slipping, instability, tilted surfaces, or balance unless the user mentioned them.
- Do NOT use any diagnostic or definitive language.
- Frame everything as "one thing to watch" or "an experiment".

FIELD MAPPING (STRICT STYLE):

session_insight:
"Since you chose [Focus Skill], one thing to watch next session is whether you’re [Scenario A] or [Scenario B]."
Example: "Since you chose pop-up timing, one thing to watch next session is whether you’re getting to your feet while the board still feels lifted, or after it starts to tip forward."

progress_pattern:
A general statement about how that skill feels to track.
Example: "Timing can be hard to feel at first, so noticing when you stand up is the main pattern to track."

next_session_focus:
A simple experiment to try next session.
Example: "Try popping up a touch earlier and notice whether the board feels more stable underneath you."

OUTPUT FORMAT:
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

SYSTEM_PROMPT = """
You are a surf coach analyzing one session.

Your job:
Identify the SINGLE most likely mechanical mistake based on the session data.

Output exactly 3 things — no more, no less:
1. What happened (specific and physical — describe body position or timing)
2. Why it happened (mechanical cause only — not psychological, not motivational)
3. One exact fix (a physical cue that is testable next session)

════════════════════════════════════════
RULES — ALL MANDATORY
════════════════════════════════════════
- No vague phrases. Every sentence must describe something visible on film.
- No encouragement language of any kind.
- Do not use: "sounds like", "coming together", "pretty good", "making progress", "getting there", "almost there", "keep at it", "great effort", "trust the process"
- Do not use slang: dude, rad, epic, awesome, stoked, gnarly, sick, crushing it
- Do not use coaching buzzwords: crucial, enhance, refine, performance, execution, prioritize, mechanics, highlights
- Must describe body position or timing — not feelings or mindset
- The fix must be specific enough to film-check

════════════════════════════════════════
STRICT DATA BOUNDARY — DO NOT VIOLATE
════════════════════════════════════════
- You may ONLY reference the selected focus skill and the user’s specific reflection inputs.
- DO NOT infer wave shape, steepness, or conditions unless explicitly stated in the notes or conditions field.
- DO NOT mention paddle speed, stance depth, or weight distribution unless the user explicitly mentioned them.
- DO NOT assume timing errors like “too late” or “too early” unless the user directly supports this with their own words.
- If the user's reflection is vague, you MUST shift to observational guidance (e.g., "One thing to notice next time is...") instead of a definitive diagnosis.
- NEVER pretend to have observed the session via video; you only have the user's text.

════════════════════════════════════════
TONE
════════════════════════════════════════
Calm. Direct. Grounded. No slang.
Write like a coach reviewing footage, not a friend giving encouragement.

════════════════════════════════════════
FIELD MAPPING
════════════════════════════════════════
session_insight  → What happened + why (2 sentences max)
  Sentence 1: Specific body position or timing error, and when in the wave it occurred
  Sentence 2: The mechanical consequence — what went wrong as a result

progress_pattern → Where the surfer is right now (1 sentence, honest, no flattery)
  State the specific technical stage — not how they feel about it

next_session_focus → One physical fix (1 sentence)
  Name the exact body movement or timing cue
  It must be specific enough to test and observe on film

════════════════════════════════════════
CORRECT EXAMPLES — FOLLOW THIS STANDARD
════════════════════════════════════════

WRONG session_insight:
"Your timing is coming together and your paddling is getting better."

CORRECT session_insight:
"The pop-up is happening after the wave face has already steepened, so the feet land on a tilted surface with weight already shifted to the tail — this is causing the board to slide out in the first 2 seconds."

---

WRONG progress_pattern:
"You're making great progress and almost there!"

CORRECT progress_pattern:
"Catching waves consistently but losing them at takeoff — the entry isn't the problem, the pop-up timing is."

---

WRONG next_session_focus:
"Work on your pop-up timing and balance."

CORRECT next_session_focus:
"Pop up while the wave is still lifting the tail — before the face steepens — and land with the front knee bent at roughly 90 degrees."

---

WRONG next_session_focus:
"Try to paddle a bit harder before takeoff."

CORRECT next_session_focus:
"Take 3 full strokes after feeling the wave grab the board, then pop — the board needs forward speed before you stand."

════════════════════════════════════════
BODY CUE VOCABULARY
════════════════════════════════════════
Use these exact terms to name errors:
- "weight too far back" → tail sinks, board decelerates
- "standing up straight at takeoff" → no rail pressure, board destabilises
- "pop-up after the face steepens" → feet land off-balance on a tilted surface
- "paddle speed drops before takeoff" → wave overtakes the board, no forward drive
- "arms too low during paddle" → less power per stroke, slower catch
- "back foot landing behind the fins" → board pivots instead of tracking forward
- "looking down at the board" → weight shifts forward, wave-reading lost
- "grabbing the rail at takeoff" → delays pop-up, shifts weight asymmetrically
- "paddling past the peak" → face already flattening when the surfer stands

════════════════════════════════════════
OUTPUT LENGTH
════════════════════════════════════════
- session_insight: 2 sentences maximum
- progress_pattern: 1 sentence
- next_session_focus: 1 sentence
- focus_tag: 3 words maximum (e.g. "takeoff timing", "paddle entry", "weight distribution")

════════════════════════════════════════
DATA RICHNESS — ADJUST CERTAINTY TO MATCH INPUT
════════════════════════════════════════
The user message will include a DATA_RICHNESS label: THIN, MODERATE, or RICH.
You MUST match your certainty level to the data richness. This is not optional.

THIN (few or no reflection answers provided):
- Keep it short and punchy. Less explanation, more clarity.
- Do NOT make definitive claims. You have no evidence. Frame everything as a possibility or check.
- Frame the insight around the Focus Area chosen by the user.
- Use language like: "Since you chose [Focus Skill], one thing to check...", "Late [Focus Skill] can make...", "Try [Focus Skill Adjustment] and notice whether...".
- Do NOT say "the pop-up is happening..." or "the board is sliding out" as if they are facts.

  session_insight → WHAT TO CHECK (Possibility-framed awareness cue)
    Use: "Since you chose [Focus Skill], one thing to check is whether...", "One thing to notice next session is..."
    Example: "Since you chose pop-up timing, one thing to check next session is whether you’re standing up while the board still feels lifted, or after it starts to tip forward."

  progress_pattern → WHAT THAT CAN CAUSE (Hedged pattern)
    Use: "[Issue] can make [Result] feel...", "When that happens, it can lead to..."
    Example: "Late pop-ups can make balance feel harder right at takeoff, even when the wave was caught cleanly."

  next_session_focus → WHAT TO EXPERIMENT WITH (Experiment-based action)
    Use: "Try [Action] and notice whether...", "Experiment with [Action] and see if..."
    Example: "Try popping up a touch earlier and notice whether the board feels more stable underneath you."

THIN EXAMPLE — CORRECT:
  session_insight: "Since you chose pop-up timing, one thing to check is whether you're standing up while the board still feels lifted, or after it starts to drop."
  progress_pattern: "Late pop-ups can make balance feel harder right at takeoff, even when the wave was caught cleanly."
  next_session_focus: "Try popping up a touch earlier and notice whether the board feels more stable underneath you."

THIN EXAMPLE — WRONG (definitive, diagnostic, mechanical):
  session_insight: "Your pop-up is too late because you are waiting for the wave to break."
  progress_pattern: "Late timing causes the board to pearl and makes you lose your balance."
  next_session_focus: "Stand up earlier next session to avoid falling."


MODERATE (some reflection answers provided, but sparse):
- You can reference what the user mentioned, but still hedge on absolute cause.
- Transition from "check this" to "it seems like".
- Use: "Based on what you described…", "If that's the pattern…", "It seems like..."
- Do not invent details not present in the input.

RICH (detailed reflection answers — specific observations):
- Be precise and confident. Use diagnostic language.
- You have the data to support specific claims.
- Use: "This is happening because...", "The result is...", "To fix this, you must..."
- Example: "The pop-up is happening after the face steepens, causing the weight to shift too far forward."
- Still do not invent — only state what the input supportively proves.

════════════════════════════════════════
OUTPUT FORMAT
════════════════════════════════════════
Return a valid JSON object with exactly these keys:
- "session_insight_en", "progress_pattern_en", "next_session_focus_en", "focus_tag_en"
- "session_insight_es", "progress_pattern_es", "next_session_focus_es", "focus_tag_es"
"""

def generate_reflection(focus: str, worked_on: str, felt_hard: str, felt_good: str, conditions: str, notes: str, language: str = "en", history: list = None, wave_height: str = "", board: str = "") -> dict:
    """
    Calls OpenAI to generate the 3-part structured JSON reflection.
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

    # 3. Hard conditional for LOW-DATA MODE vs DIAGNOSTIC
    # Triggered if both primary feedback fields are empty
    is_low_data = (n_felt_good == "" and n_felt_hard == "")
    
    if is_low_data:
        active_prompt = LOW_DATA_SYSTEM_PROMPT + "\n\nCRITICAL: LOW DATA MODE ACTIVE. Do not diagnose."
        prompt_mode = "LOW_DATA"
    else:
        active_prompt = SYSTEM_PROMPT
        prompt_mode = "DIAGNOSTIC"

    print(f"[DataAudit] isLowDataMode: {is_low_data}")
    print(f"[DataAudit] PROMPT_MODE: {prompt_mode}")

    # Format history for context if available
    history_text = ""
    if history:
        history_text = "RECENT SESSION HISTORY:\n" + "\n".join([
            f"- Session: Focus: {s.get('sessionFocus', 'N/A')}, Outcome: {s.get('aiNextFocusEn', 'N/A')}"
            for s in history[:3]
        ]) + "\n\n"

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

DATA_RICHNESS is {data_richness}. Adjust certainty accordingly. Do not invent details not present above.
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
        "session_insight_en": "We couldn't fully analyze this session, but your inputs were recorded.",
        "progress_pattern_en": "Log a few more sessions to build a clearer pattern.",
        "next_session_focus_en": "Pick one small adjustment to focus on next session.",
        "focus_tag_en": "timing",
        "session_insight_es": "No pudimos analizar completamente esta sesión, pero tus datos fueron registrados.",
        "progress_pattern_es": "Registra algunas sesiones más para ver un patrón más claro.",
        "next_session_focus_es": "Elige un pequeño ajuste en el que enfocarte la próxima sesión.",
        "focus_tag_es": "tiempo",
    }

    raw_content = ""
    try:
        raw_content = response.choices[0].message.content
        print(f"\nRAW LLM RESPONSE:\n{raw_content}\n")

        # Layer 1: direct parse (happy path — model returned clean JSON)
        try:
            parsed = json.loads(raw_content)
            print("PARSED JSON SUCCESS (layer 1 — direct)")
            return parsed
        except json.JSONDecodeError:
            pass

        # Layer 2: extract first {...} block (handles extra prose around JSON)
        import re
        match = re.search(r'\{.*\}', raw_content, re.DOTALL)
        if match:
            try:
                parsed = json.loads(match.group(0))
                print("PARSED JSON SUCCESS (layer 2 — extracted substring)")
                return parsed
            except json.JSONDecodeError:
                pass

        # Layer 3: fallback
        print(f"PARSE FAILED — returning fallback. Raw output was:\n{raw_content}")
        return FALLBACK

    except Exception as e:
        print(f"PARSE FAILED — unexpected error: {e}. Raw content: {raw_content!r}")
        return FALLBACK
