# Agent Instructions

- Commit messages: title ≤ 80 chars. Add a body only when the title
  isn't enough to explain the change — usually it is.
- Ask the user to approve changes before committing.
- Use a branch for new changes; merge to `main` once finalized. Never
  edit or commit directly on `main`.
- Never delete commits on `main`. To undo, add a revert commit on
  top — no exceptions.
- Nvim config changes: note the Nvim version being targeted, matching
  the style of older Nvim commits.
- Keep code comments minimal: only explain non-obvious rationale, never
  restate what the code already says. Skip comments entirely when the
  code is self-explanatory.
- README.md is setup-only (install, dependencies, how to run things).
  Don't document individual features, keymaps, or commands there —
  that belongs in commit messages/code, not the README.
- Every commit/feature that needs something beyond `git pull` to take
  effect on an already-bootstrapped machine (a new package, a symlink,
  a one-time command) must ship with the manual steps to apply it —
  re-running the full `bootstrap.sh` on every change is too heavy.
  Still keep `bootstrap.sh` itself updated in the same commit, so a
  fresh machine stays fully covered by it.
