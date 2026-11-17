# 05. Workflows

Step-by-step recipes. `ws` means `bin/ws`. Put `bin/` on your PATH or call it
by path.

## W1. First setup, on the first machine

Choose the directory first. Any location works except the ones listed under
"Where the workspace directory can live" in `02-architecture.md`.

```bash
cd ~/path/to/workspace
git init && git add -A && git commit -m "Workspace skeleton"
export PATH="$PWD/bin:$PATH"      # also add to ~/.zshrc or ~/.bashrc

ws add <name> <git-url> --tags <a,b> --desc "<one line>"   # repeat per repo
./bootstrap.sh

git add -A && git commit -m "Add first repos"
git remote add origin <private-workspace-url>
git push -u origin main
```

Then run `tests/smoke.sh` once on this OS and work through
`08-pilot-checklist.md`.

## W2. Set up another machine

```bash
git clone <private-workspace-url> ~/path/to/workspace
cd ~/path/to/workspace
./bootstrap.sh
export PATH="$PWD/bin:$PATH"      # also add to the shell profile
```

The workspace may live at a different path on each machine. Links are created
per machine and point at the local path.

Bootstrap needs git and access to each project's remote, for example an SSH
key registered with the git host. It does not install Claude Code or any other
tool.

## W3. Add a repo

A repo that is not on this machine yet:

```bash
ws add admin-tool git@github.com:you/admin-tool.git --tags internal --desc "Internal admin dashboard"
git add repos.conf CLAUDE.md && git commit -m "Add admin-tool" && git push
```

A repo you already have cloned somewhere else on this machine:

```bash
mv ~/projects/admin-tool repos/admin-tool
ws add admin-tool "$(git -C repos/admin-tool remote get-url origin)" --no-clone --desc "Internal admin dashboard"
git add repos.conf CLAUDE.md && git commit -m "Add admin-tool" && git push
```

Moving keeps uncommitted and unpushed work. Other machines get the repo on
their next `ws sync`.

## W4. Daily routine

| When | Command | Why |
|---|---|---|
| Sitting down at a machine | `ws sync` | Pull the workspace, clone repos added elsewhere, fast-forward every clean repo, refresh links |
| Before leaving a machine | `ws status` | See every repo with uncommitted or unpushed work, then commit and push what should travel |

## W5. A task that spans several repos

1. Start the agent at the workspace root.
2. Name the repos in the prompt when you know them. Otherwise the agent uses
   the repo index in `CLAUDE.md`.
3. The agent reads each repo's own instructions, then the files it needs.
4. Changes are committed inside each project repo, dependency first.
5. Finish with `ws status` and push each repo.

For read-only questions about another repo, the `repo-scout` subagent keeps
that repo's files out of the main conversation.

## W6. Deep work on one repo

1. Start the agent inside `repos/<name>`. That repo's instructions and skills
   load at start, and the workspace `CLAUDE.md` loads too.
2. To read a sibling repo, refer to it as `../<other>`. To also load the
   sibling's skills, start with `claude --add-dir ../<other>`.

## W7. Add or change a shared skill or agent

```bash
mkdir -p shared/skills/<name>
$EDITOR shared/skills/<name>/SKILL.md        # or: shared/agents/<name>.md
ws link
git add shared && git commit -m "Add <name> skill" && git push
```

Edit under `shared/`, never under `~/.claude`. What each operation requires
(create, update, delete, rename, copy mode) and troubleshooting are in
`10-shared-skills-and-agents.md`.

## W8. Parallel work on the same repo

Use git worktrees so that two agents do not edit the same checkout:

```bash
git -C repos/orders-api worktree add ../orders-api--fix-queue -b fix-queue
# the worktree is at repos/orders-api--fix-queue
git -C repos/orders-api worktree remove ../orders-api--fix-queue    # when done
```

A worktree placed next to its repo under `repos/` is ignored by the workspace
repo and is not in the manifest. Claude Code and Herdr also have their own
worktree features. Any of them is fine, because the worktree always belongs to
the project repo and never to the workspace.

`ws status` shows worktree work under the row of the repo it belongs to: a
linked worktree with uncommitted changes, and any branch with commits that are
on no remote. `ws grep`, `ws pull` and `ws exec` use the main checkout only.

## W9. Remove a repo

```bash
ws remove <name>
git add repos.conf CLAUDE.md && git commit -m "Remove <name>" && git push
```

The clone stays in `repos/<name>` on every machine until someone deletes it
by hand. `ws` never deletes clones.

## W10. Move or rename the workspace directory

Move the directory, then run `ws link`. The old links point at the old path,
and `ws link` replaces them. Update the PATH line in the shell profile.

## W11. Change `ws` itself

1. Read the portability rules at the top of `bin/ws`.
2. Make the change and add a check to `tests/smoke.sh`.
3. Run `tests/smoke.sh`. It must pass on macOS and Linux.
4. Update `09-ws-reference.md` and the `ws help` text.
