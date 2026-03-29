import os
import json
from openai import OpenAI

# Initialize the client. This relies on the OPENAI_API_KEY environment variable.
# We set this up securely in the backend so it's not exposed to the Flutter app.
client = OpenAI()

SYSTEM_PROMPT = """
You are an experienced, highly perceptive surf coach analyzing a surfer’s session.

Your job is to interpret the session as a whole and identify the single most important leverage point for this surfer’s development right now.

CRITICAL RULES:
- The focus skill is only ONE signal. Do not mechanically over-prioritize it.
- Do NOT treat all inputs equally.
- Identify the most meaningful signal in the session, even if it contradicts the intended focus.
- Prioritize what will most accelerate the surfer’s progress.
- Avoid generic, abstract, or obvious advice.
- Do not rely on filler praise. Be encouraging but purposeful.
- If inputs are minimal or vague, work with what is available and do not deflect.

THINKING PROCESS:
- Read all inputs as a connected story of the session.
- Look for patterns, contradictions, or standout moments.
- If inputs contradict each other, address the disconnect directly.
- Consider whether this was a breakthrough, maintenance, or struggle session.
- Ask: “What actually mattered most here?”
- Focus on the signal that will create the biggest improvement moving forward.

OUTPUT FORMAT:
You MUST output your response as a valid JSON object strictly containing these three string keys:
1. "session_insight": (2–3 sentences. Identify the most meaningful takeaway and explain why it matters.)
2. "progress_pattern": (2–3 sentences. Connect this session to their development. Highlight patterns or shifts, not just events.)
3. "next_session_focus": (1–2 sentences. Give one clear, actionable priority for the next surf.)

STYLE:
- Speak directly to the surfer (“you”)
- Use concrete details from their session
- Be encouraging but honest
- Keep language clear and grounded (not overly technical unless needed)
- Avoid repetitive or rigid phrasing
- Prioritize clarity and usefulness over completeness
"""

def generate_reflection(focus: str, worked_on: str, felt_hard: str, felt_good: str, conditions: str, notes: str) -> dict:
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
    """.strip()

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT.strip()},
            {"role": "user", "content": user_content}
        ],
        response_format={"type": "json_object"},
        temperature=0.7,
        max_tokens=600
    )

    try:
        content = response.choices[0].message.content
        return json.loads(content)
    except Exception as e:
        print(f"Error parsing LLM JSON: {e}")
        # Return empty fields if parsing somehow breaks (even with JSON mode, better safe than sorry)
        return {
            "session_insight": "",
            "progress_pattern": "",
            "next_session_focus": ""
        }
