-- Boot layout: pin the daily driver apps to fixed workspaces without
-- stealing focus, so the desktop is instantly usable. Triggered on demand
-- with SUPER SHIFT + U. Skips any app that already has a window open, since
-- several of these (ghostty, zed) are single-instance and would otherwise
-- just hand a new window to the existing process, breaking the one-shot
-- workspace rule.
local function launch_missing_on_workspace(class_pattern, command, workspace)
  if #hl.get_windows({ class = class_pattern }) == 0 then
    hl.exec_cmd(o.launch(command), { workspace = workspace .. " silent" })
  end
end

function omarchy_launch_workspace_session()
  launch_missing_on_workspace("^firefox$", "firefox", "1")
  launch_missing_on_workspace("^com\\.mitchellh\\.ghostty$", "ghostty", "2")
  launch_missing_on_workspace("^org\\.speedcrunch\\.speedcrunch$", "speedcrunch", "3")
  launch_missing_on_workspace("^md\\.obsidian\\.Obsidian$", "obsidian", "3")
  launch_missing_on_workspace("^org\\.keepassxc\\.KeePassXC$", "keepassxc", "10")
  launch_missing_on_workspace("^dev\\.zed\\.Zed$", "zed", "11")
end

o.bind("SUPER + SHIFT + U", "Launch workspace apps", omarchy_launch_workspace_session)
