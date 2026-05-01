import os
import json
from openai import OpenAI

# Initialize the client. This relies on the OPENAI_API_KEY environment variable.
# We set this up securely in the backend so it's not exposed to the Flutter app.
client = OpenAI()

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
- Do NOT make specific mechanical claims. You have no evidence for them.
- Do NOT over-explain mechanics. Prioritize feel-based cues over technical phrasing.
- Do NOT repeat the same phrase or idea. If it's in one field, don't use it in others.
- Each field must feel distinct, providing a NEW layer the surfer can remember in the water.

  session_insight → WHAT TO NOTICE (Awareness cue — one physical sensation)
    Focus on what the surfer FEELS. Short and direct.
    Sensory cues: "board rising", "tipping forward", "losing balance at takeoff", "nose dipping", "tail lifting".
    Use: "Notice if...", "Watch for the moment...", "Feel for..."

  progress_pattern → WHAT THAT USUALLY CAUSES (The pattern)
    One downstream consequence. Keep it to one short sentence.
    Use: "This usually leads to...", "When this happens...", "That typically causes..."

  next_session_focus → WHAT TO TRY (Simple adjustment — one concrete action)
    A simple cue for the next session. Something they can chant in their head.
    Use: "Next session, try...", "Before you stand...", "Look toward..."

THIN EXAMPLE — CORRECT:
  session_insight: "Feel for the moment the wave lifts your tail before you start to move."
  progress_pattern: "Waiting until the board levels out usually causes the nose to dip and lose speed."
  next_session_focus: "Try to stand up while the board is still rising, not after it starts to drop."

THIN EXAMPLE — WRONG (too long, over-explained, repetitive):
  session_insight: "Pay attention to your pop-up timing and whether you are standing up too late or too early."
  progress_pattern: "Pop-up timing is very important because if you are late you land on a steeper face which makes balance hard."
  next_session_focus: "Work on your timing next session by standing up earlier when you feel the wave."


MODERATE (some reflection answers provided, but sparse):
- You can reference what the user mentioned, but hedge on cause.
- Use: "Based on what you described…", "If that's the pattern…", "One thing to check is…"
- Do not invent details not present in the input.

RICH (detailed reflection answers — what felt hard, specific observations):
- You can make specific mechanical observations tied directly to what the user described.
- You can use direct language: "The pop-up is happening after the face steepens…"
- Still do not invent — only state what the input supports.

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

    # Format history for context if available
    history_text = ""
    if history:
        history_text = "RECENT SESSION HISTORY:\n" + "\n".join([
            f"- Session: Focus: {s.get('sessionFocus', 'N/A')}, Outcome: {s.get('aiNextFocusEn', 'N/A')}"
            for s in history[:3]
        ]) + "\n\n"

    # Compute data richness so the model knows how certain it can be
    reflection_fields = [felt_good, felt_hard, worked_on, notes, conditions]
    filled = sum(1 for f in reflection_fields if f and f.strip())
    if filled == 0:
        data_richness = "THIN"
    elif filled <= 2:
        data_richness = "MODERATE"
    else:
        data_richness = "RICH"

    user_content = f"""
{history_text}DATA_RICHNESS: {data_richness}

Session details:
- Focus area: {focus or 'not specified'}
- Wave height: {wave_height or 'not specified'}
- Board: {board or 'not specified'}
- Conditions: {conditions or '[not provided]'}
- What felt good: {felt_good or '[not provided]'}
- What felt tricky: {felt_hard or '[not provided]'}
- What they were working on: {worked_on or '[not provided]'}
- Notes: {notes or '[not provided]'}

DATA_RICHNESS is {data_richness}. Adjust certainty accordingly. Do not invent details not present above.
Write the response now. Follow all tone and structure rules.
    """.strip()

    import hashlib
    prompt_hash = hashlib.md5(SYSTEM_PROMPT.encode()).hexdigest()[:8]

    print("\n" + "="*60)
    print("SMART SURF — PROMPT SENT TO OPENAI")
    print("="*60)
    print(f"MODEL: gpt-4o-mini | TEMPERATURE: 0.4 | PROMPT HASH: {prompt_hash}")
    print("-"*60)
    print("SYSTEM PROMPT:\n", SYSTEM_PROMPT.strip())
    print("-"*60)
    print("USER MESSAGE:\n", user_content)
    print("="*60 + "\n")

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT.strip()},
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

