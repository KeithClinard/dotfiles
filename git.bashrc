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

############################
# Git compound commands
############################
alias gup=$'git pull --rebase && git remote update origin --prune && git fetch -p && for branch in $(git for-each-ref --format \'%(refname) %(upstream:track)\' refs/heads | awk \'$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}\'); do git branch -D $branch; done'
alias gbail="git reset --hard HEAD@{upstream} && git clean -fd"
alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %Cblue<%an>%Creset' --abbrev-commit --date=relative"
alias save="git add . && git commit -m f && git push"

############################
# Create new branch and push to github
############################
gnew() {
  local branchName=$1
  git checkout -b $branchName
  git push --set-upstream origin $branchName
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