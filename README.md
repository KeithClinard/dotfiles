# dotfiles

### Install

Add the following to your `.bashrc`.

```shell
############################
# Variables
############################
export GIT_DIRECTORY=/git # Location where your git repositories are cloned
DOTFILES=$GIT_DIRECTORY/dotfiles # Location of your dotfiles

############################
# Source the shared configuration files
############################
source $DOTFILES/ember.bashrc
source $DOTFILES/git.bashrc
source $DOTFILES/linux.bashrc
source $DOTFILES/shell.bashrc
```

### Git worktrees

Use worktrees to develop multiple branches of the same repository in separate
VS Code windows. The helpers require Bash or Zsh, Git, and the `code` command on your PATH.
New worktrees live at `$GIT_DIRECTORY/worktrees/<repo>/<branch>`, where `<repo>` is
the original clone's directory name. Branch slashes become subdirectories.
Repository directory names should be unique within this shared location.

| Command | Behavior |
| --- | --- |
| `gwt` | Run native `git worktree` commands and options. |
| `gwtls` | List all worktrees for the current repository. |
| `gwtnew <branch> [start-ref]` | Create a branch and worktree, attempt to push, then open a new VS Code window. |
| `gwta <branch>` | Add a worktree for an existing local branch and open a new VS Code window. |
| `gwtr <branch>` | Remove the branch's worktree, preserving the branch. |

For example, from your original clone or any of its linked worktrees:

```bash
gwtnew feature/login          # Start from the current HEAD
gwtnew fix/session main       # Start from local main
gwtls
gwta existing-local-branch
gwtr feature/login            # Run from outside the worktree being removed
```

`gwtnew` pushes to `origin` with `--set-upstream --no-verify`, skipping local
pre-push hooks. A failed push prints a warning and still opens VS Code; it does
not make the command fail if VS Code opens successfully. Neither creation helper
fetches, and `gwta` does not push. To attach a remote branch, first create a local
tracking branch, for example `git branch --track feature/login origin/feature/login`.

If VS Code cannot open, the worktree remains available and the helper prints a
manual opening command. You can reopen any listed worktree with
`code --new-window <path>` and navigate with `cd <path>`.

Removal refuses the original clone and any worktree containing your current
directory. Git also refuses dirty or locked worktrees; the helper does not force
removal. `gup` skips checked-out branches when cleaning up branches whose upstream
has disappeared, printing their worktree paths. It still deletes other branches
with missing upstreams using its existing force-delete policy.

Dependencies and build artifacts must be installed separately in each worktree
as needed. These helpers support non-bare repositories.
