status is-interactive; or return

__good_git_cleanup_omafish_wrappers

# Core
__good_git_abbr_sync g "git"
__good_git_abbr_sync gcl "git clone"

# Status
__good_git_abbr_sync gst "git status"
__good_git_abbr_sync gss "git status -s"

# Branch
__good_git_abbr_sync gb "git branch -vv"
__good_git_abbr_sync gba "git branch -a -v"
__good_git_abbr_sync "gbd!" "git branch -d"
__good_git_abbr_sync "gbD!" "git branch -D"
__good_git_abbr_sync gbm "git branch --move"

# Checkout
__good_git_abbr_sync gco "git checkout"
__good_git_abbr_sync gcom "git checkout (__good_git_default_branch)"
__good_git_abbr_sync gcb "git checkout -b"

# Commit
__good_git_abbr_sync gc "git commit -v"
__good_git_abbr_sync "gc!" "git commit -v --amend"
__good_git_abbr_sync "gcn!" "git commit -v --no-edit --amend"
__good_git_abbr_sync gca "git commit -v -a"
__good_git_abbr_sync "gca!" "git commit -v -a --amend"
__good_git_abbr_sync "gcan!" "git commit -v -a --no-edit --amend"
__good_git_abbr_sync gcv "git commit -v --no-verify"
__good_git_abbr_sync gcav "git commit -a -v --no-verify"
__good_git_abbr_sync "gcav!" "git commit -a -v --no-verify --amend"
__good_git_abbr_sync gcm "git commit -m"
__good_git_abbr_sync gcam "git commit -a -m"

# Diff and log
__good_git_abbr_sync gd "git diff"
__good_git_abbr_sync gdc "git diff --cached"
__good_git_abbr_sync gl "git log"
__good_git_abbr_sync gls "git log --stat"
__good_git_abbr_sync glg "git log --oneline --decorate --color --graph"

# Pull and push
__good_git_abbr_sync gp "git pull"
__good_git_abbr_sync gup "git pull --rebase"
__good_git_abbr_sync gP "git push"
__good_git_abbr_sync "gP!" "git push --force-with-lease"
__good_git_abbr_sync gPn "git push --no-verify"
__good_git_abbr_sync "gPn!" "git push --no-verify --force-with-lease"
__good_git_abbr_sync gpu "git push origin (__good_git_current_branch) --set-upstream"
__good_git_abbr_sync gpa "git push origin --all"
__good_git_abbr_sync gpt "git push origin --tags"

# Rebase
__good_git_abbr_sync gr "git rebase"
__good_git_abbr_sync gra "git rebase --abort"
__good_git_abbr_sync grc "git rebase --continue"
__good_git_abbr_sync gri "git rebase --interactive"

# Stash
__good_git_abbr_sync gsta "git stash"
__good_git_abbr_sync gstp "git stash pop"
__good_git_abbr_sync gstl "git stash list"
__good_git_abbr_sync gstd "git stash drop"

# Local file ops
__good_git_abbr_sync ga "git add"
__good_git_abbr_sync gaa "git add --all"
__good_git_abbr_sync grm "git rm"
__good_git_abbr_sync grmc "git rm --cached"

# Safety-sensitive operations
__good_git_abbr_sync gclean "git clean -di"
__good_git_abbr_sync "gclean!" "git clean -dfx"
__good_git_abbr_sync "gclean!!" "git reset --hard; and git clean -dfx"
__good_git_abbr_sync gm "git merge"
__good_git_abbr_sync grf "git revert"
__good_git_abbr_sync "grp!" "git reset --hard HEAD"
