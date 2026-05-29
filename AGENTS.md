# Repository Instructions

This repository must use the global `repo-lifecycle` skill for repository
management work.

Before branch creation, commits, pushes, merges, releases, or other Git workflow
changes, Codex must:

1. Read and follow `/Users/mz/.codex/skills/repo-lifecycle/SKILL.md`.
2. Show a short lifecycle plan and wait for explicit user approval before
   executing it, unless the user has already given explicit approval for the
   exact narrow action.
3. Inspect and report:
   - current branch and working-tree status;
   - `dev` and `origin/dev` state;
   - whether the current branch is based on current `dev`;
   - active unfinished feature branches;
   - whether the requested action preserves the linear lifecycle.

The expected lifecycle is:

```text
master -> dev -> feature branch -> commits -> push -> merge to dev -> next feature branch from dev
```

Do not create a new feature branch from another feature branch unless the user
explicitly approves a stacked-branch exception after seeing the current branch
topology.

If current useful work lives on a feature branch while `dev` has moved,
reverted, or diverged, stop before implementation and ask whether to:

- merge or reinstate the feature line into `dev`;
- rebuild or cherry-pick the requested work from current `dev`;
- abandon or archive the old feature branch;
- explicitly continue with a stacked branch as an exception.

Do not treat the existence of the global skill as automatic enforcement. This
file is the repo-local routing instruction: for this repository, invoke and
follow the global skill whenever Git lifecycle work is in scope.
