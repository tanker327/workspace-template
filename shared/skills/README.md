# Shared skills

Each subdirectory that contains a `SKILL.md` is one skill. `ws link` installs
every skill here into `~/.claude/skills/<name>`, so it is available in every
Claude Code session on the machine, whichever repo the session starts in.

- Add a skill: create `shared/skills/<name>/SKILL.md`, run `ws link`, commit.
- Remove a skill: delete its directory, run `ws link` (it prunes the old link).
- A skill used by only one project belongs in that project's own
  `.claude/skills/`, not here.

Why skills live here and not in `.claude/skills/` at the workspace root is
explained in `docs/03-context-loading.md`.

Edit skills here, never under `~/.claude`. The entries there are links to
these files. Full guide: `docs/10-shared-skills-and-agents.md`.
