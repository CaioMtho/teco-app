---
name: conventional-commits
description: "Compose and optionally create Conventional Commits. Never create commits without explicit user authorization."
argument-hint: "Commit summary (e.g. 'feat(profile): add avatar upload')"
user-invocable: true
---

# Conventional Commits Skill

## Scope
Guidance, validation, and optional creation of commit messages following the Conventional Commits specification.

## Outcome
Produces standardized commit messages ready for use.  
When explicitly authorized by the user, may create one or more commits if splitting changes improves semantic clarity or granularity.

## When To Use
- Prepare commit messages for PRs.
- Create commits after explicit user authorization.
- Split unrelated or overly broad changes into smaller semantic commits.

## Required Inputs
- Commit objective or summary.
- Optional diff or modified file list.

## Supported Types
- `feat`
- `fix`
- `docs`
- `style`
- `refactor`
- `perf`
- `test`
- `chore`
- `build`
- `ci`
- `revert`

## Workflow
1. Receive the change description and optional diff/file list.
2. Suggest 2–3 Conventional Commit message variations when appropriate.
3. Optionally suggest a commit body containing:
   - Main responsibilities changed.
   - Relevant implementation notes.
   - `BREAKING CHANGE:` section when applicable.
4. If the repository contains untracked or unstaged files, ask whether to include:
   - `all`
   - `staged only`
   - `select files`
5. Request explicit confirmation before creating commits.
6. If necessary, suggest splitting changes into multiple commits and confirm each separately.

## Rules
- Never create commits without explicit user authorization.
- Never auto-commit changes.
- Prefer semantic clarity over minimizing commit count.
- Avoid mixing unrelated concerns in the same commit.

## Quality Gate (Definition of Done)
- Commit message follows Conventional Commits syntax.
- Commit scope and intent are clear.
- Breaking changes are explicitly documented.
- Created commits contain only approved changes.

## Common Pitfalls
- Mixing refactor, feature, and fix changes in one commit.
- Omitting `BREAKING CHANGE:` for incompatible changes.
- Using vague subjects like `update stuff` or `fix issues`.

## Example Commit Messages
- `refactor(profile): rename main_page feature to profile`
- `refactor(shell): reorganize app shell structure`
- `fix(auth): add app icon to login screen`
- `feat(app): add application icon and display name`
- `fix(geocoding): display editable real location name`
- `fix(requests_map_page): update modal colors`
- `fix(requests_map_page): hide location button while modal is open`
- `fix(app_constants): reduce request radius to 15km`
- `fix(map): prioritize device location over profile location`

## Example Prompts
- `/conventional-commits Suggest commit message for profile changes`
- `/conventional-commits Create commit: feat(profile): add avatar upload`

## Notes
This skill prioritizes:
- Safety through explicit authorization.
- Semantic consistency.
- Review-friendly commit history.