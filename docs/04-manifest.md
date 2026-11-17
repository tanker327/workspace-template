# 04. The manifest: repos.conf

`repos.conf` lists every project repo in the workspace. It is the single
source of truth. The repo list in `CLAUDE.md` is generated from it.

## Format

The file uses git-config syntax, the same as `.gitmodules`. One section per
repo:

```ini
[repo "orders-api"]
    url = git@github.com:you/orders-api.git
    tags = shop,service
    desc = Order service. Owns the orders schema

[repo "storefront"]
    url = git@github.com:you/storefront.git
    tags = shop,web
    desc = Web shop front end. Calls orders-api
```

Lines starting with `#` or `;` are comments. Git keeps them when it rewrites
the file.

## Keys

| Key | Required | Meaning |
|---|---|---|
| `url` | Yes | Clone URL. Any form `git clone` accepts |
| `tags` | No | Comma-separated labels. Used by `--tag` in `ws list`, `clone`, `status`, `pull`, `grep`, `exec` |
| `desc` | No | One line describing the repo. Shown to agents in the `CLAUDE.md` repo index. Say what it does and how it relates to other repos |
| `path` | No | Clone location, as a relative path under `repos/`, such as `repos/group/<name>`. Default `repos/<name>`. `ws add` rejects anything else, and `ws doctor` warns about a hand-edited one: a clone outside `repos/` is not ignored by the workspace repo, and an absolute path differs between machines |

A repo exists in the manifest when it has a `url`.

## Names

The name in `[repo "name"]` is also the directory name under `repos/`.

- Allowed characters: letters, digits, `-` and `_`.
- No dots and no spaces.
- Case is preserved and significant.

`ws add` enforces this. `ws doctor` flags a hand-edited name that breaks it.

## Changing the manifest

Prefer `ws`. It validates the name, updates the `CLAUDE.md` index and clones:

```bash
ws add orders-api git@github.com:you/orders-api.git --tags shop,service \
       --desc "Order service. Owns the orders schema"
ws remove orders-api    # manifest only. The clone stays on disk
```

To change one value, use git directly, then refresh the index:

```bash
git config -f repos.conf repo.orders-api.tags shop,service,core
git config -f repos.conf repo.orders-api.desc "New description"
ws index
```

If you forget `ws index`, `ws doctor` and `ws index --check` report that the
list in `CLAUDE.md` is out of date.

## Reading the manifest

```bash
ws list                                   # table for people and agents
ws path orders-api                        # absolute path of one repo

git config -f repos.conf repo.orders-api.url  # one value
git config -f repos.conf --get-regexp '^repo\.'             # everything
git config -f repos.conf --name-only --get-regexp '^repo\..*\.url$'   # names
```

## Why git-config

See decision D3 in `01-design.md`. In short: git parses it, so bootstrap needs
nothing but git, and it behaves the same on macOS and Linux.

## Limits of the format

| Limit | Effect |
|---|---|
| Key names allow only letters, digits and hyphens | Use `default-branch`, not `default_branch` |
| One level of nesting: section, then key | A list is comma-separated in one value |
| Values are single-line strings | Keep `desc` to one line |

## Adding a new key

New keys need no schema change. To make `ws` use one:

1. Read it with `repo_get <name> <key>` in `bin/ws`.
2. Document it in the table above and in the comment header of `repos.conf`.
3. Add a check to `tests/smoke.sh`.

Keys that would be reasonable later: `default-branch`, `setup` (a command to
run after cloning), `machines` (limit a repo to named machines).
