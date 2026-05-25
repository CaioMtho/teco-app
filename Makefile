.PHONY: help install analyze test build clean run gen-icons format lint doctor update

# Flutter via FVM
FLUTTER := fvm flutter
DART := fvm dart

help:
	@echo "TECO Makefile Commands"
	@echo "===================="
	@echo "install        - Get dependencies"
	@echo "analyze        - Run dart analyzer"
	@echo "test           - Run all tests"
	@echo "build-apk      - Build Android APK"
	@echo "build-aab      - Build Android App Bundle"
	@echo "build-ipa      - Build iOS IPA"
	@echo "build-web      - Build Web"
	@echo "build-linux    - Build Linux"
	@echo "build-windows  - Build Windows"
	@echo "build-macos    - Build macOS"
	@echo "clean          - Clean build"
	@echo "run            - Run app (default device)"
	@echo "run-release    - Run app release mode"
	@echo "gen-icons      - Generate app icons"
	@echo "format         - Format Dart code"
	@echo "fix            - Auto-fix Dart issues"
	@echo "lint           - Lint check"
	@echo "doctor         - Flutter doctor"
	@echo "update         - Update dependencies"
	@echo "pubget         - pub get"
	@echo "pubupgrade     - pub upgrade"

install: pubget

pubget:
	$(FLUTTER) pub get

pubupgrade:
	$(FLUTTER) pub upgrade

update: pubupgrade

analyze:
	$(FLUTTER) analyze

lint: analyze

test:
	$(FLUTTER) test

format:
	$(DART) format lib/ test/

fix:
	$(DART) fix lib/ test/ --apply

clean:
	$(FLUTTER) clean

gen-icons:
	$(FLUTTER) pub run flutter_launcher_icons:main

build-apk:
	$(FLUTTER) build apk --release

build-aab:
	$(FLUTTER) build appbundle --release

build-ipa:
	$(FLUTTER) build ios --release

build-web:
	$(FLUTTER) build web --release

build-linux:
	$(FLUTTER) build linux --release

build-windows:
	$(FLUTTER) build windows --release

build-macos:
	$(FLUTTER) build macos --release

run:
	$(FLUTTER) run

run-release:
	$(FLUTTER) run --release

doctor:
	$(FLUTTER) doctor -v
