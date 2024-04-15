Copy linter.* into the base of your target git repo.

Then run `./linter.sh install` over there for commit-hook linting.

And instead of using `git commit -a`, which will skip the linter hook, use `git add -u; git commit`. I have an alias for this in my shell.
