# Workspace

One git repo that manages many project repos. It gives coding agents a single
entry point with shared context, shared skills and shared subagents, and it
lets you rebuild the same setup on another computer with one command.

Project code does not live in this repo. Each project stays an independent git
repo, cloned under `repos/`.

## Quick start

```bash
# 1. Put this folder where you want it, then make it a git repo.
#    Any location works except a cloud-synced folder or inside another repo.
cd ~/path/to/workspace
git init && git add -A && git commit -m "Workspace skeleton"

# 2. Put ws on your PATH. Add this line to ~/.zshrc or ~/.bashrc, written
#    with $HOME so it works on machines with a different user name.
export PATH="$HOME/path/to/workspace/bin:$PATH"

# 3. Register a few repos. Each is cloned into repos/<name>.
ws add orders-api git@github.com:YOU/orders-api.git --tags shop --desc "What it does"

# 4. Install shared skills and agents into ~/.claude and check the setup.
./bootstrap.sh

# 5. Push the workspace to a private remote so other machines can clone it.
git add -A && git commit -m "Add first repos"
git remote add origin git@github.com:YOU/workspace.git && git push -u origin main
```

On another computer: `git clone <workspace-url> && cd workspace && ./bootstrap.sh`.

If the scripts are not executable after unzipping: `chmod +x bin/ws bootstrap.sh tests/smoke.sh`.

## Layout

```
workspace/
├── CLAUDE.md        Instructions every agent session loads. Keep it short
├── AGENTS.md        Pointer to CLAUDE.md for tools that look for AGENTS.md
├── repos.conf       The list of project repos (git-config format)
├── bootstrap.sh     Set up or repair this machine. Safe to re-run
├── bin/ws           Helper for working across repos (`ws help`)
├── shared/
│   ├── skills/      Skills for all projects, installed into ~/.claude/skills
│   └── agents/      Subagents for all projects, installed into ~/.claude/agents
├── docs/            Design docs. Start at docs/README.md
├── tests/smoke.sh   Self-contained test of ws. Touches nothing outside a temp dir
└── repos/           Project repos are cloned here. Ignored by this repo
```

## Everyday commands

| Command | What it does |
|---|---|
| `ws sync` | Pull the workspace, clone anything new, pull every clean repo, relink |
| `ws status` | Show uncommitted and unpushed work in every repo |
| `ws list` | Show all repos, their tags, and whether each is cloned |
| `ws add <name> <url>` | Register and clone a repo |
| `ws grep <pattern>` | Search all repos |
| `ws doctor` | Check that this machine is set up correctly |

Full reference: `docs/09-ws-reference.md`.

## Shared skills and agents

Create, edit and delete them in `shared/`, never in `~/.claude`. Run `ws link`
after adding, renaming or deleting one. Editing an existing one needs no
command. See `docs/10-shared-skills-and-agents.md`.

## Status

This is a pilot. `docs/08-pilot-checklist.md` lists what to verify before adding
more repos. `ws` was tested on Linux with bash 5; run `tests/smoke.sh` once on
macOS to confirm it behaves the same there.
