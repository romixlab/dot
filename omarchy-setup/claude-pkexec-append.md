
# Root on Omarchy: pkexec

On this Omarchy PC, run a step that needs root yourself with `pkexec <command>`: the Omarchy shell's polkit agent shows the person the exact command in a password dialog, they approve it there, and the output comes back to you. This replaces handing over a `sudo` command to run or paste, and filing root as an ask. One pkexec per step, the plain command, no `sh -c` wrapping, so the dialog shows what runs. If the dialog is cancelled or times out, say in words what is needed and why, and stop.
