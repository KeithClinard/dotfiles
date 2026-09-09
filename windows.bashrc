set bell-style none

############################
# Open windows explorer here
############################
alias e="explorer ."

############################
# Open current repo in github
############################
gopen() {
  git remote -v | head -n 1 | awk -F "@" '{print $2}' | awk -F " " '{print $1}' | sed 's/:/\//g' | sed 's/.git$//g' | awk '{print "http://"$1}' | xargs start
}

############################
# Fix Cygwin path
############################
export PATH=$HOME/bin:/usr/local/bin:$PATH
