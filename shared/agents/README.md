# Shared subagents

Each `.md` file here, except this README, is one Claude Code subagent
definition: YAML frontmatter (`name`, `description`, optional `tools` and
`model`) followed by the system prompt. `ws link` installs each one into
`~/.claude/agents/`.

- Add an agent: create `shared/agents/<name>.md`, run `ws link`, commit.
- Remove an agent: delete the file, run `ws link`.
- An agent used by only one project belongs in that project's `.claude/agents/`.
  A project-level agent overrides a shared one with the same name.

If a linked agent does not show up in `/agents` on some machine, switch that
machine to copy mode with `ws link --copy`. See `docs/08-pilot-checklist.md`.

Edit agents here, never under `~/.claude`. The entries there are links to
these files. Full guide: `docs/10-shared-skills-and-agents.md`.
