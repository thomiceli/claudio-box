#!/bin/sh
# claudio-box's command. The home is a volume that starts empty: it gets the
# usual dotfiles, then Claude Code, installed there on the first start and
# updated at every start. Remote Control needs a claude.ai login (a setup-token
# isn't enough), which only a person with a browser can give: until it's there,
# it waits (see the README).
set -eu

# The volume hides the image's home
for f in .bashrc .profile .bash_logout; do
  [ -e "$HOME/$f" ] || cp "/etc/skel/$f" "$HOME/$f"
done

# Where the sessions work (clone projects here)
mkdir -p "$HOME/work"
cd "$HOME/work"

if ! command -v claude >/dev/null 2>&1; then
  echo "Installing Claude Code in $HOME"
  curl -fsSL https://claude.ai/install.sh | bash
else
  claude update || echo "Claude Code update failed, starting the installed version"
fi

# remote-control's two questions, which it exits on without a terminal to ask:
# "Enable Remote Control?" (yes, it's what this box is for) and whether to trust
# ~/work (where its sessions work). Answered in ~/.claude.json, where it keeps
# them, while no claude runs.
config="$HOME/.claude.json"
[ -s "$config" ] || echo '{}' > "$config"
if jq --arg dir "$PWD" '.remoteDialogSeen = true | .projects[$dir].hasTrustDialogAccepted = true' \
    "$config" > "$config.new"; then
  mv "$config.new" "$config"
else
  echo "Couldn't answer Remote Control's questions in $config"
fi

if ! claude auth status >/dev/null 2>&1; then
  echo "Waiting for the first login: run 'kubectl exec -it deploy/claudio -- claude auth login' (see the README)"
  until claude auth status >/dev/null 2>&1; do sleep 10; done
fi

# Its screen (stdout) is redrawn every second, a log line each time, so it goes
# nowhere; its errors and warnings (stderr) still reach the pod's logs.
# Sessions show up as claudio-... in claude.ai/code, in auto mode: what Claude
# judges safe runs without asking you on the phone.
echo "Starting Remote Control"
exec claude remote-control --remote-control-session-name-prefix claudio --permission-mode auto >/dev/null
