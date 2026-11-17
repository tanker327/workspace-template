# Workspace design docs

These docs explain how the workspace is built and why. They are written for
coding agents and for the owner. Read them when you need to change the
workspace itself, or when something about context loading is unclear. For
ordinary project work, the workspace `CLAUDE.md` is enough.

## Reading order

| Doc | Read it when |
|---|---|
| [01-design.md](01-design.md) | You want the goals and the reasoning behind each decision |
| [02-architecture.md](02-architecture.md) | You want to know what each file is and how the parts connect |
| [03-context-loading.md](03-context-loading.md) | Instructions, skills or agents are not loading as expected |
| [04-manifest.md](04-manifest.md) | You need to read or change `repos.conf` |
| [05-workflows.md](05-workflows.md) | You need steps for a task: new machine, add a repo, cross-repo change |
| [06-multi-machine-sync.md](06-multi-machine-sync.md) | You work on more than one computer |
| [07-herdr.md](07-herdr.md) | You run agents inside Herdr |
| [08-pilot-checklist.md](08-pilot-checklist.md) | You are validating the setup before scaling it up |
| [09-ws-reference.md](09-ws-reference.md) | You need exact `ws` command behavior, or want to extend `ws` |
| [10-shared-skills-and-agents.md](10-shared-skills-and-agents.md) | You are creating, changing or deleting a shared skill or subagent, or one is not showing up |

## Terms

| Term | Meaning |
|---|---|
| Workspace | This directory and its git repo. Also called the meta repo |
| Project repo | One independent git repo cloned under `repos/` |
| Manifest | `repos.conf`, the list of project repos |
| Shared skill, shared agent | A skill or subagent in `shared/`, installed for every project |
| Launch point | The directory where a Claude Code session is started |

## How claims are labelled

Statements about Claude Code behavior carry one of three labels, because the
tool changes often and some behavior here has not been confirmed on the
owner's machines yet.

| Label | Meaning |
|---|---|
| **Documented** | Stated in Anthropic's Claude Code docs, checked on 2026-11-15 |
| **Tested** | Reproduced while building this workspace. The doc says how |
| **Inferred** | Follows from the docs but not confirmed. Has a pilot check in 08 |

When you confirm or refute an Inferred claim, update its label and the pilot
checklist.

## Keeping these docs true

- Change the doc in the same commit as the behavior it describes.
- Record a new decision as a row in the table in `01-design.md`. Do not rewrite
  history: mark a replaced decision as superseded and add a new row.
- Keep the workspace `CLAUDE.md` short. Detail belongs here.
