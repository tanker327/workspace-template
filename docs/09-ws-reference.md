# 09. ws reference

`bin/ws` is a single bash script. It needs bash 3.2 or later and git. It finds
the workspace root from its own location, so it works from any directory and
through a symlink on PATH.

## Commands

### Setup

| Command | Behavior |
|---|---|
| `ws bootstrap` | Runs `clone`, `link`, then `doctor`. Safe to repeat. `./bootstrap.sh` is the same thing |
| `ws sync [--no-self]` | Pulls the workspace repo and restarts itself, then `clone`, `pull`, `link`, `status`. `--no-self` skips the workspace pull |
| `ws doctor` | Checks git, where the workspace lives, the manifest, `.gitignore`, `CLAUDE.md` and its repo index, every repo and its path, and the links. Exits 1 only on a failure, not on warnings |

### Repos

| Command | Behavior |
|---|---|
| `ws list [--tag T]` | Table of name, state (`cloned` or `missing`), tags and path |
| `ws add NAME URL [--tags a,b] [--desc "text"] [--path repos/DIR] [--no-clone]` | Validates the name and path, writes the manifest, regenerates the `CLAUDE.md` index, clones. Fails if the name exists, or if `--path` is not a relative path under `repos/`. If the clone fails, the manifest entry is removed again, so nothing is left half-added |
| `ws remove NAME` | Deletes the manifest section and regenerates the index. Leaves the clone on disk |
| `ws clone [--tag T] [NAME...]` | Clones missing repos. Skips ones already cloned. Refuses a non-empty directory that is not a git repo |
| `ws path NAME` | Prints the absolute path. Exits 1 for an unknown name |
| `ws index` | Rewrites the block between `<!-- ws:repos:start -->` and `<!-- ws:repos:end -->` in `CLAUDE.md` |
| `ws index --check` | Changes nothing. Exits 1 when that block no longer matches `repos.conf` |

### Across repos

| Command | Behavior |
|---|---|
| `ws status [--tag T]` | One row per repo, plus the workspace repo: branch, changed-file count, ahead and behind counts. Under a row, a `+` line for each other local branch with commits that are on no remote, for stashes, and for each linked worktree with uncommitted changes. Ends with totals. Reads local refs only: it does not fetch |
| `ws pull [--tag T]` | `git pull --ff-only` in each repo that is cloned, clean and has an upstream. Reports and skips the rest |
| `ws grep [--tag T] [GIT-GREP-OPTIONS] PATTERN` | `git grep -n -I` in each cloned repo, with paths prefixed by the repo's location. Tracked files only. Exits 1 when nothing matches |
| `ws exec [--tag T] -- COMMAND [ARGS...]` | Runs the command inside each cloned repo. Exits 1 if any run failed |

### Shared skills and agents

| Command | Behavior |
|---|---|
| `ws link` | Installs each `shared/skills/<name>/` containing a `SKILL.md`, and each `shared/agents/*.md` except `README.md`, into the Claude config directory. Removes installs whose source was deleted. Exits 1 if a name was already taken by something else |
| `ws link --copy` | Switches this machine to copy mode and remembers it in `.ws.local`. Copies are refreshed on every `ws link` |
| `ws link --symlink` | Switches this machine back to symlinks |
| `ws unlink` | Removes everything `ws link` installed. Touches nothing else |

## Options and environment

| Name | Meaning |
|---|---|
| `--tag T`, `-t T` | Limit the command to repos whose `tags` include `T` |
| `CLAUDE_CONFIG_DIR` | Claude Code config directory. Default `~/.claude` |

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | The command ran but something failed or was refused. Details are on stderr |
| 2 | Unknown command |

## Files `ws` writes

| File | Written by |
|---|---|
| `repos.conf` | `add`, `remove` |
| `CLAUDE.md`, only between the index markers | `add`, `remove`, `index` |
| `repos/<name>/` | `clone`, `add`, `sync`, `bootstrap` |
| `.ws.local` | `link --copy`, `link --symlink` |
| `~/.claude/skills/*`, `~/.claude/agents/*`, `~/.claude/.ws-managed` | `link`, `unlink` |

## Use by agents

Agents should prefer these, which are read-only and safe at any time:
`ws list`, `ws path`, `ws status`, `ws grep`, `ws doctor`.

These change state and should follow a request from the owner:
`ws add`, `ws remove`, `ws pull`, `ws sync`, `ws link`, `ws unlink`.

Output is plain text. Color is used only when stdout is a terminal.

## Extending `ws`

The portability rules are in the comment at the top of `bin/ws`. In short:

- It must run on macOS's stock bash 3.2. No associative arrays, `mapfile`,
  `${var,,}`, or `local -n`.
- No GNU-only flags such as `readlink -f`, `sed -i`, `realpath`, `grep -P`.
- With `set -u`, never expand an array that may be empty.
- Keep all code inside functions, with `main "$@"` as the last statement, so
  the file is fully parsed before running and `ws sync` can update it safely.
- Options that take a value call `need_val` first.

To add a command: write `cmd_<name>`, add it to the `case` in `main` and to
`cmd_help`, add checks to `tests/smoke.sh`, and document it here. The smoke
test fails when a command in `ws help` is missing from this file.

## Testing

```bash
tests/smoke.sh           # all checks, in a temp directory with a fake HOME
KEEP=1 tests/smoke.sh    # keep the temp directory to inspect it
```

The test builds local bare repos to act as remotes, simulates two machines,
and exercises every command. It uses no network and never touches the real
`~/.claude` or real repos.

Where the test has been run, and with which versions, is recorded under P1 in
`08-pilot-checklist.md`. Run it again after changing `ws`.
