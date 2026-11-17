# Workspace

You are in a multi-repo workspace. This directory is a "meta repo": it holds no
product code. Every project is its own independent git repo cloned under
`repos/`. This file sits at the workspace root and Claude Code loads it in every
session started here or inside any repo below, so it is kept short on purpose.

## Map

| Path | What it is |
|---|---|
| `repos/<name>/` | One independent git repo per project. Gitignored by the workspace repo |
| `repos.conf` | The list of repos (git-config format). Source of truth |
| `bin/ws` | Helper for working across repos. Run `ws help` |
| `shared/skills/`, `shared/agents/` | Skills and subagents shared by all projects, installed into `~/.claude/` |
| `docs/` | Design docs for this workspace. Start at `docs/README.md` |

If `ws` is not on PATH, call it by path: `bin/ws` from the workspace root, or
`../../bin/ws` from inside `repos/<name>`.

## Repos

<!-- Generated from repos.conf by `ws index`. Do not edit between the markers. -->
<!-- ws:repos:start -->
_No repos yet. Add one with `ws add <name> <git-url>`._
<!-- ws:repos:end -->

## Rules

1. **Commit inside the project repo.** Use `git -C repos/<name> ...` or `cd` into
   it. Never `git add` anything under `repos/` from the workspace repo.
2. **Search with an explicit repo path.** A search from the workspace root skips
   `repos/` because it is gitignored here. Search `repos/<name>` directly, or run
   `ws grep <pattern>` to search every repo.
3. **Find sibling repos by name.** `ws list` shows all repos and `ws path <name>`
   prints a location. From inside one repo, a sibling is at `../<name>`.
4. **A repo's own instructions win.** When you work inside `repos/<name>`, its
   CLAUDE.md or AGENTS.md overrides anything general written here.
5. **Cross-repo changes are one commit per repo.** Change the repo that is
   depended on first, then its consumers. Say which commits belong together.
6. **Change the repo list with `ws add` and `ws remove`.** They update
   `repos.conf` and the list above together.
7. **Check before leaving a machine.** `ws status` shows uncommitted and unpushed
   work in every repo. Unpushed work does not reach other machines.
8. **No `@` imports in this file.** Refer to other files by plain path in
   backticks. The reason is in `docs/03-context-loading.md`.
9. **Shared skills and agents are edited in `shared/`, never in `~/.claude`.**
   The entries in `~/.claude` are links to `shared/`. After adding, renaming or
   deleting one, run `ws link`. A skill or agent for one project only goes in
   that project's `.claude/` instead. Details: `docs/10-shared-skills-and-agents.md`.
10. **No absolute paths in tracked files.** The user name and home directory
    differ between machines. Write `~/...`, `$HOME/...`, a path relative to the
    workspace root, or `$(ws path <name>)`. Never `/Users/<name>/...` or
    `/home/<name>/...`.

## When you need more

- Why the workspace is built this way: `docs/01-design.md`
- How context, skills and agents load: `docs/03-context-loading.md`
- Step-by-step tasks (new machine, add a repo, cross-repo change): `docs/05-workflows.md`
- Creating, changing or deleting a shared skill or agent: `docs/10-shared-skills-and-agents.md`
