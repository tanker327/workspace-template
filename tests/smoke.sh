#!/usr/bin/env bash
#
# Smoke test for bin/ws. Runs entirely inside a temp directory with a fake
# HOME, so it never touches your real ~/.claude, your repos, or the network.
#
#   tests/smoke.sh          run all checks
#   KEEP=1 tests/smoke.sh   keep the temp directory for inspection
#
# Run this once on each new kind of machine (macOS, Linux) to confirm that
# ws behaves the same there. Must stay bash 3.2 compatible, like bin/ws.

set -u

SRC="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d 2>/dev/null || mktemp -d -t wstest)"
TMP="$(cd -P "$TMP" && pwd)"   # macOS: /var -> /private/var
PASS=0
FAIL=0

cleanup() {
  if [ "${KEEP:-0}" = "1" ]; then
    echo "kept: $TMP"
  else
    rm -rf "$TMP"
  fi
}
trap cleanup EXIT

pass() { PASS=$((PASS + 1)); printf '  ok    %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }

# check "description" command...   passes when the command succeeds
check() {
  local desc="$1"
  shift
  if "$@" >"$TMP/last.out" 2>&1; then pass "$desc"; else
    fail "$desc"
    sed 's/^/        /' "$TMP/last.out"
  fi
}

# refute "description" command...  passes when the command fails
refute() {
  local desc="$1"
  shift
  if "$@" >"$TMP/last.out" 2>&1; then
    fail "$desc"
    sed 's/^/        /' "$TMP/last.out"
  else pass "$desc"; fi
}

has() { grep -qF -- "$2" "$1"; }          # has FILE TEXT
out_has() { "${@:2}" 2>&1 | grep -qF -- "$1"; }   # out_has TEXT command...

# ------------------------------------------------------------ fixtures ----

export HOME="$TMP/homeA"
mkdir -p "$HOME"
unset CLAUDE_CONFIG_DIR
git config --global user.name "ws test"
git config --global user.email "ws-test@example.invalid"
git config --global init.defaultBranch main
git config --global advice.detachedHead false

# make_remote NAME  -> a bare repo with one commit containing a marker line
make_remote() {
  local name="$1" work="$TMP/seed-$1"
  git init -q --bare "$TMP/remotes/$name.git"
  git init -q "$work"
  printf 'NEEDLE_%s lives here\n' "$name" > "$work/file.txt"
  printf '# %s\n' "$name" > "$work/README.md"
  git -C "$work" add -A
  git -C "$work" commit -q -m "init $name"
  git -C "$work" remote add origin "$TMP/remotes/$name.git"
  git -C "$work" push -q -u origin main
}

mkdir -p "$TMP/remotes"
make_remote alpha
make_remote beta
make_remote gamma

# The workspace under test: a copy of this one, without any cloned repos.
WS="$TMP/machineA/workspace"
mkdir -p "$WS"
for entry in "$SRC"/* "$SRC"/.[!.]*; do
  [ -e "$entry" ] || continue
  case "$(basename "$entry")" in
    repos|.git|.ws.local) continue ;;
  esac
  cp -R "$entry" "$WS/"
done
mkdir -p "$WS/repos" && touch "$WS/repos/.gitkeep"
ws() { "$WS/bin/ws" "$@"; }

echo "ws smoke test in $TMP"
echo "bash $BASH_VERSION, $(git --version)"
echo

# --------------------------------------------------------------- basics ----

echo "basics"
check  "help runs"                         ws help
check  "list works with an empty manifest" ws list
refute "unknown command fails"             ws frobnicate
refute "option without a value fails instead of hanging" ws list --tag
refute "clone of an unknown repo fails"    ws clone nope
refute "path of an unknown repo fails"     ws path nope

# ------------------------------------------------------------------ add ----

echo "add / list / path / index"
check  "add clones the repo" ws add alpha "$TMP/remotes/alpha.git" --tags svc,core --desc "Alpha service"
check  "clone exists"                      test -d "$WS/repos/alpha/.git"
check  "manifest has the url"              test "$(git config -f "$WS/repos.conf" repo.alpha.url)" = "$TMP/remotes/alpha.git"
check  "manifest comments are preserved"   has "$WS/repos.conf" "# Keys per repo:"
check  "CLAUDE.md index lists alpha"       has "$WS/CLAUDE.md" '- **alpha** (`repos/alpha`): Alpha service _[svc,core]_'
check  "CLAUDE.md keeps its rules"         has "$WS/CLAUDE.md" "## Rules"
check  "add --no-clone only records"       ws add beta "$TMP/remotes/beta.git" --tags svc --no-clone
refute "beta is not cloned yet"            test -e "$WS/repos/beta"
check  "list shows beta as missing"        out_has "missing" ws list
refute "adding a duplicate fails"          ws add alpha "$TMP/remotes/alpha.git"
refute "invalid name is rejected"          ws add "bad.name" "$TMP/remotes/alpha.git"
refute "a path outside repos/ is rejected" ws add delta "$TMP/remotes/alpha.git" --path apps/delta
refute "an absolute path is rejected"      ws add delta "$TMP/remotes/alpha.git" --path "$TMP/abs/delta"
refute "a path with .. is rejected"        ws add delta "$TMP/remotes/alpha.git" --path repos/../delta
refute "a rejected path records nothing"   has "$WS/repos.conf" '[repo "delta"]'
check  "a path under repos/ is accepted"   ws add delta "$TMP/remotes/alpha.git" --path repos/group/delta --no-clone
check  "path honors the custom location"   test "$(ws path delta)" = "$WS/repos/group/delta"
ws remove delta >/dev/null 2>&1
refute "add fails when the clone fails"    ws add ghost "$TMP/remotes/no-such-repo.git"
refute "a failed add leaves nothing in the manifest" has "$WS/repos.conf" '[repo "ghost"]'
refute "a failed add leaves nothing in the index" has "$WS/CLAUDE.md" '**ghost**'
check  "clone fetches the missing repo"    ws clone
check  "beta is cloned now"                test -d "$WS/repos/beta/.git"
check  "clone is idempotent"               ws clone
check  "path prints the absolute path"     test "$(ws path alpha)" = "$WS/repos/alpha"
check  "list --tag filters"                test "$(ws list --tag core | grep -c cloned)" = "1"

# -------------------------------------------------------- nesting rules ----

echo "workspace repo vs project repos"
git -C "$WS" init -q
git -C "$WS" add -A
git -C "$WS" commit -q -m "init workspace"
refute "workspace repo does not track project files" \
  sh -c "git -C '$WS' ls-files | grep -q '^repos/alpha/'"
check  "workspace repo tracks repos/.gitkeep" \
  sh -c "git -C '$WS' ls-files | grep -qx 'repos/.gitkeep'"

# ----------------------------------------------------------------- grep ----

echo "grep / exec"
check  "grep finds text in alpha"          out_has "repos/alpha/file.txt:1:NEEDLE_alpha" ws grep NEEDLE_
check  "grep finds text in beta"           out_has "repos/beta/file.txt:1:NEEDLE_beta" ws grep NEEDLE_
check  "grep --tag limits the repos"       test "$(ws grep --tag core NEEDLE_ | wc -l | tr -d ' ')" = "1"
refute "grep with no match exits non-zero" ws grep NO_SUCH_TEXT_ANYWHERE
check  "exec runs in every repo"           test "$(ws exec -- git rev-parse --abbrev-ref HEAD | grep -c '^main$')" = "2"

# --------------------------------------------------------------- status ----

echo "status / pull"
check  "status reports a clean, synced repo" out_has "in sync" ws status
echo "local edit" >> "$WS/repos/alpha/file.txt"
check  "status reports uncommitted changes" out_has "1 changed" ws status
git -C "$WS/repos/alpha" commit -q -am "local commit"
check  "status reports unpushed commits"   out_has "ahead 1, behind 0" ws status
git -C "$WS/repos/alpha" push -q

# Work that is not on the checked-out branch of the main checkout.
git -C "$WS/repos/alpha" checkout -q -b side
echo "side edit" >> "$WS/repos/alpha/file.txt"
git -C "$WS/repos/alpha" commit -q -am "side commit"
git -C "$WS/repos/alpha" checkout -q main
check  "status reports an unpushed commit on another branch" \
  out_has "branch side: 1 commit(s) not on any remote" ws status
# 2: alpha, plus the workspace repo itself, which has no upstream yet.
check  "status counts that repo as unpushed" out_has "2 with unpushed commits" ws status
git -C "$WS/repos/alpha" push -q origin side
refute "a pushed branch is no longer reported" out_has "branch side" ws status
echo "stashed edit" >> "$WS/repos/alpha/file.txt"
git -C "$WS/repos/alpha" stash -q
check  "status reports a stash"            out_has "stashes: 1" ws status
git -C "$WS/repos/alpha" stash drop -q
git -C "$WS/repos/alpha" worktree add -q ../alpha--task -b task
echo "worktree edit" >> "$WS/repos/alpha--task/file.txt"
check  "status reports a dirty linked worktree" \
  out_has "worktree repos/alpha--task (task): 1 changed" ws status
git -C "$WS/repos/alpha" worktree remove --force ../alpha--task
git -C "$WS/repos/alpha" branch -q -D task
refute "a clean repo has no extra lines"   out_has "  + " ws status

# Someone else pushes to beta.
git clone -q "$TMP/remotes/beta.git" "$TMP/other-beta"
echo "remote edit" >> "$TMP/other-beta/file.txt"
git -C "$TMP/other-beta" commit -q -am "remote commit"
git -C "$TMP/other-beta" push -q
check  "pull fast-forwards a clean repo"   ws pull
check  "beta received the remote commit"   has "$WS/repos/beta/file.txt" "remote edit"

echo "another remote edit" >> "$TMP/other-beta/file.txt"
git -C "$TMP/other-beta" commit -q -am "remote commit 2"
git -C "$TMP/other-beta" push -q
echo "dirty" >> "$WS/repos/beta/README.md"
check  "pull skips a repo with uncommitted changes" out_has "has uncommitted changes" ws pull
refute "the dirty repo was not updated"    has "$WS/repos/beta/file.txt" "another remote edit"
git -C "$WS/repos/beta" checkout -q -- README.md

# ----------------------------------------------------------------- link ----

echo "link / unlink"
check  "link installs skills and agents"   ws link
check  "skill is a symlink into the workspace" \
  test "$(readlink "$HOME/.claude/skills/workspace-nav")" = "$WS/shared/skills/workspace-nav"
check  "agent is a symlink into the workspace" \
  test "$(readlink "$HOME/.claude/agents/repo-scout.md")" = "$WS/shared/agents/repo-scout.md"
check  "skill is readable through the link" test -f "$HOME/.claude/skills/workspace-nav/SKILL.md"
refute "README.md is not installed as an agent" test -e "$HOME/.claude/agents/README.md"
refute "README.md is not installed as a skill" test -e "$HOME/.claude/skills/README.md"
check  "link is idempotent"                ws link

# A skill the user already had under the same name must not be touched.
mkdir -p "$WS/shared/skills/mine" "$HOME/.claude/skills/mine"
echo "shared version" > "$WS/shared/skills/mine/SKILL.md"
echo "my own version" > "$HOME/.claude/skills/mine/SKILL.md"
refute "link reports a name conflict"      ws link
check  "the user's own skill is untouched" has "$HOME/.claude/skills/mine/SKILL.md" "my own version"
rm -rf "$WS/shared/skills/mine" "$HOME/.claude/skills/mine"

# Removing a shared skill prunes its link.
mkdir -p "$WS/shared/skills/temp-skill"
echo "temp" > "$WS/shared/skills/temp-skill/SKILL.md"
check  "link installs a new skill"         ws link
check  "new skill link exists"             test -L "$HOME/.claude/skills/temp-skill"
rm -rf "$WS/shared/skills/temp-skill"
check  "link after removal succeeds"       ws link
refute "the stale link was pruned"         test -L "$HOME/.claude/skills/temp-skill"

# Copy mode, for machines where symlinked agents are not picked up.
check  "link --copy switches to copies"    ws link --copy
refute "skill is no longer a symlink"      test -L "$HOME/.claude/skills/workspace-nav"
check  "skill copy exists"                 test -f "$HOME/.claude/skills/workspace-nav/SKILL.md"
check  "agent copy exists"                 test -f "$HOME/.claude/agents/repo-scout.md"
echo "<!-- edited -->" >> "$WS/shared/agents/repo-scout.md"
check  "copy mode is remembered"           ws link
check  "copies are refreshed from source"  has "$HOME/.claude/agents/repo-scout.md" "<!-- edited -->"
mkdir -p "$WS/shared/skills/temp2"
echo "temp2" > "$WS/shared/skills/temp2/SKILL.md"
ws link >/dev/null 2>&1
rm -rf "$WS/shared/skills/temp2"
check  "link in copy mode after removal"   ws link
refute "the stale copy was pruned"         test -e "$HOME/.claude/skills/temp2"
check  "link --symlink switches back"      ws link --symlink
check  "skill is a symlink again"          test -L "$HOME/.claude/skills/workspace-nav"
refute "no managed list is left behind"    test -e "$HOME/.claude/.ws-managed"
git -C "$WS" checkout -q -- shared/agents/repo-scout.md

check  "unlink removes what link installed" ws unlink
refute "skill link is gone"                test -e "$HOME/.claude/skills/workspace-nav"
refute "agent link is gone"                test -e "$HOME/.claude/agents/repo-scout.md"
check  "link restores them"                ws link

# --------------------------------------------------------------- doctor ----

echo "doctor"
check  "doctor passes"                     ws doctor
printf '# beta agents file\n' > "$WS/repos/beta/AGENTS.md"
check  "doctor warns about an AGENTS.md-only repo" out_has "has AGENTS.md but no CLAUDE.md" ws doctor
mkdir -p "$HOME/.claude"
printf '{"pluginConfigs":{"cc-plugin-agents-md@builtin":{"options":{"instructionFiles":"claude-md-and-agents-md"}}}}\n' > "$HOME/.claude/settings.json"
refute "the warning goes away once both files are set to load" out_has "has AGENTS.md but no CLAUDE.md" ws doctor
rm -f "$WS/repos/beta/AGENTS.md" "$HOME/.claude/settings.json"
printf '\nSee @docs/01-design.md\n' >> "$WS/CLAUDE.md"
check  "doctor warns about an @import in CLAUDE.md" out_has "contains an @import" ws doctor
git -C "$WS" checkout -q -- CLAUDE.md 2>/dev/null || true
ws index >/dev/null 2>&1

check  "index --check passes when the index is current" ws index --check
git config -f "$WS/repos.conf" repo.alpha.desc "Edited by hand"
refute "index --check fails after a hand edit of repos.conf" ws index --check
check  "doctor warns about a stale index"  out_has "repo index in CLAUDE.md is out of date" ws doctor
check  "index --check did not rewrite CLAUDE.md" has "$WS/CLAUDE.md" ': Alpha service _[svc,core]_'
git config -f "$WS/repos.conf" repo.alpha.desc "Alpha service"
check  "the index is current again"        ws index --check
refute "no stale-index warning when it is current" out_has "is out of date" ws doctor
git config -f "$WS/repos.conf" repo.stray.url "$TMP/remotes/alpha.git"
git config -f "$WS/repos.conf" repo.stray.path apps/stray
check  "doctor warns about a path outside repos/" out_has "is not a relative path under repos/" ws doctor
git config -f "$WS/repos.conf" --remove-section repo.stray

refute "no absolute-path warning for the shipped files" out_has "absolute home paths" ws doctor
mkdir -p "$WS/shared/skills/abs"
printf 'run /Users/someone/workspace/bin/ws\n' > "$WS/shared/skills/abs/SKILL.md"
check  "doctor warns about a hardcoded home path" out_has "absolute home paths" ws doctor
rm -rf "$WS/shared/skills/abs"
printf '# stray\n' > "$TMP/machineA/CLAUDE.md"
check  "doctor warns about a CLAUDE.md above the workspace" out_has "is above the workspace" ws doctor
rm -f "$TMP/machineA/CLAUDE.md"
git init -q "$TMP/machineA"
check  "doctor warns when the workspace is inside another repo" out_has "inside another git repo" ws doctor
rm -rf "$TMP/machineA/.git"
refute "no location warnings in a normal location" \
  sh -c "'$WS/bin/ws' doctor 2>&1 | grep -Eq 'above the workspace|inside another git repo|cloud-synced'"

# ----------------------------------------------------------------- docs ----

echo "docs"
MISSING=""
for c in $(ws help | sed -n 's/^  ws \([a-z]*\).*/\1/p' | sort -u); do
  grep -qF "\`ws $c" "$WS/docs/09-ws-reference.md" || MISSING="$MISSING $c"
done
check  "every command in ws help is in docs/09-ws-reference.md:$MISSING" test -z "$MISSING"

# ------------------------------------------------- invoked via a symlink ----

echo "ws on PATH through a symlink"
mkdir -p "$TMP/bin"
ln -s "$WS/bin/ws" "$TMP/bin/ws"
check  "ws finds the workspace through a symlink" \
  test "$(cd / && "$TMP/bin/ws" path alpha)" = "$WS/repos/alpha"

# ----------------------------------------------------- second machine ----

echo "second machine: clone the workspace, run bootstrap"
git init -q --bare "$TMP/remotes/workspace.git"
git -C "$WS" add -A
git -C "$WS" commit -q -m "add alpha and beta" >/dev/null 2>&1 || true
git -C "$WS" remote add origin "$TMP/remotes/workspace.git"
git -C "$WS" push -q -u origin main

HOME_A="$HOME"
export HOME="$TMP/homeB"
mkdir -p "$HOME"
git config --global user.name "ws test B"
git config --global user.email "ws-test-b@example.invalid"
git config --global init.defaultBranch main
WSB="$TMP/machineB/somewhere-else/ws"
mkdir -p "$(dirname "$WSB")"
git clone -q "$TMP/remotes/workspace.git" "$WSB"
check  "scripts are still executable after clone" test -x "$WSB/bin/ws" -a -x "$WSB/bootstrap.sh"
check  "bootstrap.sh succeeds on machine B" "$WSB/bootstrap.sh"
check  "machine B has alpha"               test -d "$WSB/repos/alpha/.git"
check  "machine B has beta"                test -d "$WSB/repos/beta/.git"
check  "machine B links point at its own path" \
  test "$(readlink "$HOME/.claude/skills/workspace-nav")" = "$WSB/shared/skills/workspace-nav"
check  "bootstrap is idempotent"           "$WSB/bootstrap.sh"

# Machine B adds a repo and a shared skill, then pushes the workspace.
check  "machine B adds gamma" "$WSB/bin/ws" add gamma "$TMP/remotes/gamma.git" --desc "Gamma"
mkdir -p "$WSB/shared/skills/from-b"
printf -- '---\nname: from-b\ndescription: test\n---\n' > "$WSB/shared/skills/from-b/SKILL.md"
git -C "$WSB" add -A
git -C "$WSB" commit -q -m "add gamma and a skill"
git -C "$WSB" push -q

# Machine A picks all of it up with one command.
export HOME="$HOME_A"
check  "ws sync succeeds on machine A"     ws sync
check  "machine A received gamma"          test -d "$WS/repos/gamma/.git"
check  "machine A index lists gamma"       has "$WS/CLAUDE.md" '- **gamma** (`repos/gamma`): Gamma'
check  "machine A linked the new skill"    test -L "$HOME/.claude/skills/from-b"
check  "sync is idempotent"                ws sync

# --------------------------------------------------------------- remove ----

echo "remove"
check  "remove drops the repo from the manifest" ws remove beta
refute "beta is no longer listed"          out_has "beta" ws list
check  "the clone is left on disk"         test -d "$WS/repos/beta/.git"
refute "CLAUDE.md index no longer lists beta" has "$WS/CLAUDE.md" '**beta**'

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
