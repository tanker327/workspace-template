# 08. Pilot checklist

The pilot runs the workspace with two or three repos before more are added.
Its job is to confirm the behavior the design assumes, on the owner's real
machines and Claude Code version. Fill in the Result column and the date.

Pick repos that actually depend on each other. A cross-repo task is the main
thing being tested.

Claude Code version tested: `2.1.326`  Date: `2026-11-16`

## Setup checks

| ID | Check | Steps | Expected | Result |
|---|---|---|---|---|
| P1 | `ws` works on this OS | `tests/smoke.sh` on macOS, and on Linux if used | All checks pass | Pass on macOS (Darwin 27.2.0, bash 3.2.57, git 2.54.0): 90 passed, 0 failed. Linux not run yet |
| P2 | Bootstrap completes | `./bootstrap.sh`, then `ws doctor` | 0 failures. Every warning understood | |

## Context loading checks

Restart Claude Code before each check so that nothing is cached.

| ID | Check | Steps | Expected | Result |
|---|---|---|---|---|
| P3 | Workspace instructions load inside a project | Start Claude Code in `repos/<name>`. Run `/memory` | Both the workspace `CLAUDE.md` and the project's are listed | |
| P4 | Shared skill and agent are available | In that same session, check the skill list for `workspace-nav` and run `/agents` for `repo-scout`. Repeat from the workspace root | Both present from both launch points | |
| P5 | Search from the root | Start at the workspace root. Ask for a string that exists only inside one project, without naming the project | Claude finds it, by using `ws grep` or an explicit `repos/<name>` path. Note whether a plain search missed it first | |
| P6 | Project instructions load on demand from the root | Start at the root. Ask Claude to read a file in `repos/<name>`. Run `/memory` | That project's `CLAUDE.md` now appears | |
| P7 | `AGENTS.md`-only repos | `ws doctor`. If it warns, apply fix 1 from G1 in `03-context-loading.md`, restart, run `/memory` inside that repo | The repo's `AGENTS.md` is listed after the fix | |
| P11 | Does a root-level `.claude/skills` reach a project? | Create `.claude/skills/probe/SKILL.md` at the workspace root with a `name` and `description`. Start Claude Code in `repos/<name>`. Look for `probe`. Delete it afterwards | Expected: not available. Either outcome is fine. Record it and update R2 in 03 and D4 in 01 | |

If P4 fails for the agent only, run `ws link --copy`, restart Claude Code and
check again. Record which OS needed copy mode.

## Workflow checks

| ID | Check | Steps | Expected | Result |
|---|---|---|---|---|
| P8 | A real cross-repo task | From the root, give Claude a task that needs a change in one repo and a matching change in another | Correct commits inside each project repo. Nothing staged under `repos/` in the workspace repo. `ws status` matches what Claude reported | |
| P9 | Second machine | On another computer: clone the workspace, run `./bootstrap.sh`. Time it | Working in a few minutes, with no manual steps beyond PATH and credentials | |
| P10 | Round trip | On machine A: `ws add` a repo, edit a shared skill, push. On machine B: `ws sync` | The new repo is cloned, and the skill change is visible in a new session | |

## Deciding what happens next

| Outcome | Action |
|---|---|
| P1 to P10 pass | Add repos a few at a time. Re-run `ws doctor` after each batch |
| P3 fails | The core assumption is wrong for this version. Stop and revisit D2 and D5 |
| P4 fails even in copy mode | Shared skills or agents need another delivery route, such as `--add-dir` or a skill manager |
| P5 shows Claude regularly missing project files | Strengthen rule 2 in `CLAUDE.md`, or default to launching inside projects |
| P6 is unreliable | Treat root sessions as coordination only. Do deep work from inside the project |
| P8 is awkward for the same pair of repos every time | Those repos may belong together in one repo |

## Notes from the pilot

Record surprises here, with the date and the Claude Code version.

-
