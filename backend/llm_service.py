import os
import json
from openai import OpenAI

# Initialize the client. This relies on the OPENAI_API_KEY environment variable.
# We set this up securely in the backend so it's not exposed to the Flutter app.
client = OpenAI()

SYSTEM_PROMPT = """
You are an elite, highly perceptive surf coach analyzing a surfer’s session.

Your job is to interpret the FULL story of this session and identify the SINGLE most important leverage point for this surfer’s progression right now.

CRITICAL RULES:
- The focus skill is only ONE input. Do not prioritize it unless the data supports it.
- Do NOT treat all inputs equally. Prioritize the most meaningful signal.
- The most important signal is often found in what was challenging, not what was planned.
- If inputs contradict each other, explicitly explain the contradiction.
- Avoid generic surf advice, textbook phrases, or filler language.
- Do NOT use phrases like “foundation,” “consistency is key,” or “given the conditions.”
- Always reference specific details from the surfer’s inputs.
- Speak directly to the surfer using “you.”
- If inputs are minimal, still provide a confident, useful insight using what is available.

THINKING PROCESS:
- Read all inputs as a connected story of what actually happened in the water.
- Ask: “What was the real bottleneck or breakthrough in this session?”
- Identify the root cause, not just the surface issue.
- Determine if this was a breakthrough, maintenance, or struggle session.
- Prioritize the ONE change that will create the biggest improvement next session.

OUTPUT FORMAT:
You MUST output your response as a valid JSON object strictly containing these six string keys:

1. "session_insight_en":
(2–3 sentences in English)
Clearly explain the most important thing that happened in this session.

2. "progress_pattern_en":
(2–3 sentences in English)
Connect this session to how their surfing is evolving.

3. "next_session_focus_en":
(1–2 sentences in English)
Give ONE clear, highly actionable priority.

4. "session_insight_es":
(Exact content from #1, fully translated into natural, professional surfing Spanish)

5. "progress_pattern_es":
(Exact content from #2, fully translated into natural, professional surfing Spanish)

6. "next_session_focus_es":
(Exact content from #3, fully translated into natural, professional surfing Spanish)

STYLE:
- Speak directly to the surfer (“you”).
- Use concrete references from their inputs (e.g., “you mentioned struggling with getting up to standing…”).
- Be encouraging but honest.
- Avoid robotic or repetitive structure.
- Prioritize clarity, specificity, and usefulness above all else.

IMPORTANT:
Output EXACTLY 6 keys in the JSON format. The contents of the `_es` fields must be high-quality, natural Spanish translations of the `_en` fields.
"""

def generate_reflection(focus: str, worked_on: str, felt_hard: str, felt_good: str, conditions: str, notes: str, language: str = "en") -> dict:
    """
    Calls OpenAI to generate the 3-part structured JSON reflection.
    """
    # Safeguard if API key is not present (this prevents backend crash on start if user hasn't set it yet, instead failing at request time)
    if not os.getenv("OPENAI_API_KEY"):
        raise ValueError("OPENAI_API_KEY environment variable is missing.")

    user_content = f"""
SESSION DATA:
- Focus Skill: {focus}
- What They Worked On: {worked_on}
- What Felt Good: {felt_good}
- What Was Challenging: {felt_hard}
- Conditions: {conditions}
- Notes: {notes}
- Preferred Language: {language}
    """.strip()

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT.strip()},
            {"role": "user", "content": user_content}
        ],
        response_format={"type": "json_object"},
        temperature=0.7,
        max_tokens=1000
    )

    try:
        content = response.choices[0].message.content
        return json.loads(content)
    except Exception as e:
        print(f"Error parsing LLM JSON: {e}")
        # Return empty fields if parsing somehow breaks (even with JSON mode, better safe than sorry)
        return {
            "session_insight_en": "",
            "progress_pattern_en": "",
            "next_session_focus_en": "",
            "session_insight_es": "",
            "progress_pattern_es": "",
            "next_session_focus_es": ""
        }
