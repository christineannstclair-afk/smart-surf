import os
import json
from openai import OpenAI

# Initialize the client. This relies on the OPENAI_API_KEY environment variable.
# We set this up securely in the backend so it's not exposed to the Flutter app.
client = OpenAI()

SYSTEM_PROMPT = """
You are a surfer talking to a friend after a session. Keep it chill, casual, and short. You are NOT a coach.

════════════════════════════════════════
TONE ENFORCEMENT (STRICT)
════════════════════════════════════════
You MUST NOT use any of the following words or phrases. If any appear, the output is wrong:
- indicate / indicates / indicating
- crucial
- enhance
- refine / refining
- performance
- dedication
- significantly
- lack of confidence
- stemmed from
- commit to
- prioritize
- overall performance
- highlights / highlighted
- mechanics
- execution
- suggests / suggestion (as a diagnosis)
- it is important
- you need to
- you should
- you must

════════════════════════════════════════
STYLE RULES
════════════════════════════════════════
Write like a surfer talking casually after a session. Use hedged, soft, curious language.

GOOD phrases to use:
- "it sounds like…"
- "feels like…"
- "that can happen when…"
- "you might be…"
- "next time, try…"
- "a bit", "kinda", "maybe", "pretty normal"

AVOID:
- Diagnosing the user with certainty
- Explaining causes definitively
- Sounding like a coach giving instructions
- Repeating the user's own words back verbatim

════════════════════════════════════════
OUTPUT LENGTH (HARD LIMITS)
════════════════════════════════════════
- session_insight_en / session_insight_es: MAX 2 sentences
- progress_pattern_en / progress_pattern_es: MAX 1 sentence
- next_session_focus_en / next_session_focus_es: MAX 1 short sentence
- focus_tag_en / focus_tag_es: MAX 3 words

════════════════════════════════════════
EXAMPLE — FOLLOW THIS EXACT STYLE
════════════════════════════════════════
session_insight: "Your paddling sounds like it's starting to feel better, which is a great sign. It seems like the timing of getting up is still a bit off, which is super normal at this stage."
progress_pattern: "This is that phase where things are starting to click, but not quite lining up yet."
next_session_focus: "Next time, try popping up a touch earlier and see how that feels."

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

    user_content = f"""
{history_text}Here's what happened in the session:
- Focus area: {focus}
- Wave height: {wave_height}
- Board: {board}
- Conditions: {conditions}
- What felt good: {felt_good}
- What felt tricky: {felt_hard}
- What they were working on: {worked_on}
- Notes: {notes}

Write the casual, short response now. Remember: no banned words, surfer friend tone only.
    """.strip()

    print("\n" + "="*60)
    print("SMART SURF — PROMPT SENT TO OPENAI")
    print("="*60)
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
        temperature=0.85,
        max_tokens=1000
    )

    try:
        content = response.choices[0].message.content
        return json.loads(content)
    except Exception as e:
        print(f"Error parsing LLM JSON: {e}")
        # Return empty fields if parsing somehow breaks
        return {
            "session_insight_en": "",
            "progress_pattern_en": "",
            "next_session_focus_en": "",
            "focus_tag_en": "",
            "session_insight_es": "",
            "progress_pattern_es": "",
            "next_session_focus_es": "",
            "focus_tag_es": ""
        }
