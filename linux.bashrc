export BROWSER=explorer.exe

############################
# Open windows explorer here
############################
alias e="explorer.exe ."

############################
# Open current repo in github
############################
gh() {
  local remote=$(git remote -v | head -n 1 | awk -F " " '{print $2}' | sed 's/.git$//g')
  if [[ "$remote" == *@* ]]; then
    remote=$(echo $remote | awk -F "@" '{print $2}' | sed 's/:/\//g' | awk '{print "https://"$1}')
  fi

  local branch=$(git branch --show-current)
  if [[ "$branch" != "main" ]]; then
    remote="$remote/tree/$branch"
  fi

  echo $remote | xargs $BROWSER || return 0
}