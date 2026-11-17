---
name: workspace-nav
description: Find, read and search other repos in the multi-repo workspace. Use when a task needs code, an API, a schema or docs from a repo other than the current one, when a change spans several repos, or when you need to know which repos exist.
---

# Working across repos in the workspace

The workspace is a directory that holds many independent git repos under
`repos/`. Its root contains `repos.conf`, `bin/ws` and a `CLAUDE.md`. If you were
started inside `repos/<name>`, the workspace root is two levels up.

## Find the workspace root

Use `ws` if it is on PATH. Otherwise walk up from the current directory until
you find a directory that contains `repos.conf`, and call `<root>/bin/ws`.

## Find a repo

```bash
ws list                 # every repo, its tags, and whether it is cloned
ws list --tag shop      # only repos with that tag
ws path <name>          # absolute path of one repo
```

If the repo you need shows `missing`, clone it with `ws clone <name>`.

## Read another repo

1. Get its path with `ws path <name>`.
2. Read that repo's `CLAUDE.md` or `AGENTS.md` and `README.md` first. They
   describe its layout and rules.
3. Read only the files the task needs. For a broad question, delegate to the
   `repo-scout` subagent so the other repo's files stay out of your context.

## Search

A search started at the workspace root skips `repos/`, because that directory is
gitignored there. Do one of these instead:

```bash
ws grep "createOrder"            # all repos, tracked files only
ws grep --tag shop "TODO"        # repos with a tag
ws grep -i -e "retry" -- "*.ts"  # any git grep options work
```

Or point the search tool at `repos/<name>` explicitly.

## Change more than one repo

1. List the repos involved and how they depend on each other.
2. Change the repo that is depended on first, then its consumers.
3. Commit inside each repo: `git -C "$(ws path <name>)" commit ...`. One commit or
   PR per repo. Never stage anything under `repos/` in the workspace repo.
4. In each commit message or PR, name the related commits in the other repos.
5. Finish with `ws status` and report which repos have unpushed work.

## Do not

- Do not edit `repos.conf` by hand when `ws add` or `ws remove` can do it.
- Do not copy code between repos to avoid a dependency without saying so.
- Do not run `git` commands at the workspace root expecting them to affect a
  project repo. The workspace repo and the project repos are separate.
