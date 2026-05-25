---
name: prefer-makefile-commands
description: "Prefer Makefile targets for running commands. Use when: run/build/test/analyze/lint/format/install/clean/doctor/update."
argument-hint: "Goal (ex: analyze, test, build-apk, run)"
user-invocable: true
---

# Prefer Makefile Commands

## Scope
Running shell commands in this repo.

## Outcome
Use `make <target>` over direct `flutter`/`dart` commands when target exists.

## When To Use
- You are about to run commands like analyze/test/build/run/format/lint/install/clean/doctor/update.
- You see `@file:Makefile` attached.

## Procedure
1. Check repo root `Makefile` for targets.
2. Map request to a Makefile target.
3. Run `make <target>` (use `make help` to list targets).
4. If no target exists, run direct command and state why.
5. If new target needed, ask user before editing Makefile.

## Known Targets (current Makefile)
- `make install`
- `make analyze`
- `make test`
- `make lint`
- `make format`
- `make fix`
- `make clean`
- `make gen-icons`
- `make build-apk`
- `make build-aab`
- `make build-ipa`
- `make build-web`
- `make build-linux`
- `make build-windows`
- `make build-macos`
- `make run`
- `make run-release`
- `make doctor`
- `make update`
- `make pubget`
- `make pubupgrade`

## Notes
Makefile uses `fvm flutter` and `fvm dart`, so targets keep toolchain consistent.

## Example Prompts
- `/prefer-makefile-commands Run analyzer`
- `/prefer-makefile-commands Build Android APK`
