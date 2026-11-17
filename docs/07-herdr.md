# 07. Using the workspace with Herdr

Optional. Nothing in the workspace depends on Herdr.

Herdr is a terminal multiplexer built for coding agents. It keeps agent
sessions alive in panes and shows which ones need attention. The workspace
and Herdr solve different problems and do not overlap:

| Concern | Handled by |
|---|---|
| Which repos exist and where they are | Workspace (`repos.conf`) |
| What context, skills and subagents an agent gets | Workspace (`CLAUDE.md`, `shared/`) |
| Identical setup on every machine | Workspace (`bootstrap.sh`, `ws sync`) |
| Running many agent sessions at once | Herdr |
| Seeing which agent is working, blocked or idle | Herdr |
| Keeping sessions alive when you disconnect | Herdr |

The details below come from Herdr's docs as of 2026-11-15 and have not been
tried with this workspace. Verify them before relying on them.

## Suggested layout

Herdr's docs suggest one Herdr workspace per repo, task or investigation.
Applied here:

| Herdr workspace | Directory | Used for |
|---|---|---|
| One for the root | The workspace root | Cross-repo tasks |
| One per active project | `repos/<name>` | Deep work on that project |

Herdr's own "workspace" is a group of tabs and panes. It is unrelated to this
workspace repo, despite the shared word.

## Sharing Herdr's config between machines

Herdr's terminal app reads `~/.config/herdr/config.toml`. To keep one config
for all machines:

1. Move that one file into a tracked location, for example
   `shared/herdr/config.toml` here, or your dotfiles repo.
2. Symlink it back: `ln -s <tracked-path> ~/.config/herdr/config.toml`.

Link the single file, not the directory. Herdr keeps session state in the
same directory, and session state must not go into git.

Herdr's docs note that some settings are read from the client's config and
others from the server where the panes run. One config file shared by a Mac
client and a Linux host is a documented setup.

`ws link` does not manage this file. It is a one-time manual step per machine.

## Two Herdr programs

There is the original terminal app (`herdr`, config in `~/.config/herdr`) and
a newer desktop app (config in `~/.config/herdr-app`). They are separate
programs and do not share agents. Apply the steps above to the one in use.

## Remote use

Herdr sessions survive a disconnect and can be reattached over SSH. Combined
with the "one host" model in `06-multi-machine-sync.md`: run the workspace and
Herdr on an always-on machine, and attach from any other computer.

## Possible later addition

Herdr exposes a CLI and a local socket API that can create a workspace in a
directory and send text to a pane. A future `ws open <name>` could read the
path from `repos.conf`, create the Herdr workspace there and start an agent.
Not built yet: decide after the pilot whether it would be used.

## Sources

- https://herdr.dev/docs/concepts/
- https://herdr.dev/docs/configuration/
- https://herdr.dev/
