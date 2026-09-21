Use setup.md file to save instructions about system configuration.
Keep it succinct, no need for detailed explanations, just what to do.

After applying every step: append one JSON object per line (JSON Lines) to ~/.config/dot.log:
{"time": "<ISO 8601 with offset>", "step_no": <setup.md step number>, "step": "<name>", "result": "applied|failed|ignored", "note": "<optional>", "sha": "<git sha>"}
