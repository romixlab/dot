Use setup.md file to save instructions about system configuration.
Keep it succinct, no need for detailed explanations, just what to do.

After applying every step: append one JSON object per line (JSON Lines) to ~/.config/dot.log:
{"time": "<ISO 8601 with offset>", "step_no": <setup.md step number>, "step": "<name>", "result": "applied|failed|ignored", "note": "<optional>", "sha": "<git sha>"}

When asked to update, read the log file, determine which steps are already done and only do the remaining, applicable ones. No need to compare everything, unless asked. Present a list of changes to be made first and ask whether to proceed first.

Before committing - ask.

Before creating or applying anything non-standard (custom scripts, modifying default ones, etc.) - ask.
