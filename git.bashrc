############################
# Git shorthand
############################
alias g="git"
alias ga="git add"
alias gf="git fetch"
alias gap="git add -p"
alias gc="git commit"
alias co="git checkout"
alias gp="git push"
alias gs="git status"
alias grb="git rebase -i"
alias grbc="git rebase --continue"
alias grba="git rebase --abort"
alias grbm="git rebase main"
alias gcp="git cherry-pick"
alias gd="git diff"
alias gclean="git clean -fd"
alias gb="git branch"
alias gcan="git commit --amend --no-edit"
alias gwt="git worktree"
alias gwtls="git worktree list"

############################
# Git compound commands
############################
# Remove the old alias when this file is sourced again in an existing shell.
unalias gup 2>/dev/null || true
gup() {
  git pull --rebase && git remote update origin --prune && git fetch -p || return

  local branch track worktree
  local result=0
  local branches
  branches=$(git for-each-ref --format='%(refname:lstrip=2) %(upstream:track)' refs/heads) || return
  while read -r branch track; do
    [[ "$track" == "[gone]" ]] || continue
    if worktree=$(_gwt_branch_path "$branch"); then
      printf 'Skipping %s: checked out in %s\n' "$branch" "$worktree"
    else
      git branch -D -- "$branch" || result=$?
    fi
  done <<< "$branches"
  return "$result"
}
alias gbail="git reset --hard HEAD@{upstream} && git clean -fd"
alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %Cblue<%an>%Creset' --abbrev-commit --date=relative"
alias save="git add . && git commit -m f && git push"

############################
# Worktrees and separate VS Code windows
############################
_gwt_validate_branch() {
  if [[ -z "$1" || "$1" == -* ]] || ! git check-ref-format "refs/heads/$1"; then
    printf 'Invalid branch name: %s\n' "$1" >&2
    return 1
  fi
}

_gwt_main_root() {
  local common field
  common=$(git rev-parse --path-format=absolute --git-common-dir) || return
  while IFS= read -r -d '' field; do
    if [[ "$field" == worktree\ * ]]; then
      (cd -- "${field#worktree }" && pwd -P)
      return
    fi
  done < <(git --git-dir="$common" worktree list --porcelain -z)
  printf 'Could not find the original worktree.\n' >&2
  return 1
}

_gwt_branch_path() {
  local field worktree_path
  git rev-parse --git-common-dir >/dev/null || return
  while IFS= read -r -d '' field; do
    case "$field" in
      worktree\ *) worktree_path=${field#worktree } ;;
      "branch refs/heads/$1") printf '%s\n' "$worktree_path"; return 0 ;;
    esac
  done < <(git worktree list --porcelain -z)
  return 1
}

_gwt_destination() {
  local root repo
  _gwt_validate_branch "$1" || return
  if [[ -z "${GIT_DIRECTORY:-}" ]]; then
    printf 'Set GIT_DIRECTORY to your repositories directory first.\n' >&2
    return 1
  fi
  root=$(_gwt_main_root) || return
  if [[ $(git rev-parse --is-bare-repository) == true ]]; then
    printf 'These helpers require a non-bare repository.\n' >&2
    return 1
  fi
  repo=${root##*/}
  printf '%s/worktrees/%s/%s\n' "${GIT_DIRECTORY%/}" "$repo" "$1"
}

_gwt_open() {
  if code --new-window "$1"; then
    return 0
  fi
  printf 'VS Code could not open the worktree at %s.\nRetry: code --new-window %q\n' "$1" "$1" >&2
  return 1
}

gwtnew() {
  if [[ $# -lt 1 || $# -gt 2 ]]; then
    printf 'Usage: gwtnew <branch> [start-ref]\n' >&2
    return 1
  fi
  local worktree_path
  worktree_path=$(_gwt_destination "$1") || return
  mkdir -p -- "${worktree_path%/*}" || return
  git worktree add -b "$1" -- "$worktree_path" "${2-HEAD}" || return
  if ! git -C "$worktree_path" push --no-verify --set-upstream origin "$1"; then
    printf 'Warning: push failed for %s; the local branch and worktree are ready at %s.\n' "$1" "$worktree_path" >&2
  fi
  _gwt_open "$worktree_path"
}

gwta() {
  if [[ $# -ne 1 ]]; then
    printf 'Usage: gwta <branch>\n' >&2
    return 1
  fi
  local worktree_path
  worktree_path=$(_gwt_destination "$1") || return
  git show-ref --verify --quiet "refs/heads/$1" || {
    printf 'Local branch does not exist: %s\n' "$1" >&2
    return 1
  }
  mkdir -p -- "${worktree_path%/*}" || return
  git worktree add -- "$worktree_path" "$1" || return
  _gwt_open "$worktree_path"
}

gwtr() {
  if [[ $# -ne 1 ]]; then
    printf 'Usage: gwtr <branch>\n' >&2
    return 1
  fi
  local worktree_path root current
  _gwt_validate_branch "$1" || return
  root=$(_gwt_main_root) || return
  worktree_path=$(_gwt_branch_path "$1") || {
    printf 'No worktree found for branch: %s\n' "$1" >&2
    return 1
  }
  worktree_path=$(cd -- "$worktree_path" && pwd -P) || return
  current=$(pwd -P) || return
  if [[ "$worktree_path" == "$root" ]]; then
    printf 'Cannot remove the original clone: %s\n' "$worktree_path" >&2
    return 1
  fi
  if [[ "$current" == "$worktree_path" || "$current" == "$worktree_path/"* ]]; then
    printf 'Leave this worktree before removing it: %s\n' "$worktree_path" >&2
    return 1
  fi
  git worktree remove -- "$worktree_path"
}

############################
# Create new branch and push to github
############################
gnew() {
  local branchName=$1
  git checkout -b $branchName
  git push --no-verify --set-upstream origin $branchName
}

############################
# Move uncommitted git changes to new branch off updated main
# Optionally commit and push the changes
############################
gmovebranch() {
  local branchName=$1
  local commitmessage=$2
  git stash push --include-untracked
  git checkout main
  gbail
  gup
  gnew $branchName
  git stash pop
  if [[ -n $commitmessage ]]; then
    git add .
    git commit -m "$commitmessage"
    git push
    gopen
  fi
}
