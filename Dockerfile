# claudio-box: an always-on Claude Code box, driven from claude.ai/code and the
# Claude app through Remote Control. Go, Node and Python are baked in. Only the
# home is a volume, so anything else goes there (mise use -g, uv tool install,
# npm i -g, go install). Claude Code isn't in the image: start.sh installs it in
# the home, where it updates itself.
FROM golang:1.27-trixie AS go
FROM ghcr.io/astral-sh/uv:0.13.8 AS uv

FROM node:26-trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl git jq less openssh-client procps \
      python3 python3-dev python3-venv ripgrep tini tmux tzdata unzip vim-tiny \
      xz-utils \
 && rm -rf /var/lib/apt/lists/*

# gh from GitHub's own repo: Debian's lags far behind
RUN curl -fsSLo /usr/share/keyrings/githubcli-archive-keyring.gpg \
      https://cli.github.com/packages/githubcli-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh

COPY --from=go /usr/local/go /usr/local/go
COPY --from=uv /uv /uvx /usr/local/bin/

# The node image's uid 1000 user, renamed. No sudo: the pod runs without
# privilege escalation, so system packages come from this file.
RUN usermod --login claude --home /home/claude --move-home node \
 && groupmod --new-name claude node

# Everything installed per user lands in the home, and is on the PATH for
# kubectl exec and Claude's shells alike
ENV HOME=/home/claude \
    LANG=C.UTF-8 \
    TZ=Europe/Paris \
    GOPATH=/home/claude/go \
    NPM_CONFIG_PREFIX=/home/claude/.npm-global \
    PATH=/home/claude/.local/bin:/home/claude/.local/share/mise/shims:/home/claude/go/bin:/home/claude/.npm-global/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

COPY start.sh /usr/local/bin/claudio-start

USER claude
WORKDIR /home/claude
# PID 1 reaps the processes the sessions' shells leave behind
ENTRYPOINT ["tini", "--"]
CMD ["claudio-start"]
