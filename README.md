# claudio-box

An always-on Claude Code box, driven from claude.ai/code and the Claude app
through Remote Control. Deployed on ragbian as `argocd/apps/claudio`.

- Debian 13 with Go, Node, Python + uv, gh, mise, tmux, ripgrep
- Runs as `claude` (uid 1000), without sudo
- Only `/home/claude` persists. Claude Code installs itself there on the first
  start and keeps itself updated; sessions work in `~/work`. Extra tools go
  there too: `mise use -g`, `uv tool install`, `npm i -g`, `go install`.

## First start

Remote Control needs a claude.ai login; the pod waits for it:

```bash
kubectl exec -it deploy/claudio -- claude auth login
```

It starts on its own within 10 s. Then GitHub, for cloning and pushing:

```bash
kubectl exec -it deploy/claudio -- gh auth login
kubectl exec -it deploy/claudio -- gh auth setup-git
kubectl exec -it deploy/claudio -- git config --global user.name "Thomas Miceli"
kubectl exec -it deploy/claudio -- git config --global user.email you@example.com
```

Both logins live in the home volume and survive restarts.

## Shell access

```bash
kubectl exec -it deploy/claudio -- tmux new -A -s main
```
