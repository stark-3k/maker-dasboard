.PHONY: all build run dev clean frontend-install frontend-dev frontend-build backend-build backend-run test-integration test-integration-docker docker-build docker-run dmg help

# macOS .app / .dmg packaging settings
APP_NAME    := Maker Dashboard
BIN_NAME    := maker-dashboard
APP_VERSION := $(shell sed -n 's/^version = "\(.*\)"$$/\1/p' Cargo.toml | head -1)
DMG_ARCH    := $(shell uname -m)
DMG_STAGING := target/dmg
APP_BUNDLE  := $(DMG_STAGING)/$(APP_NAME).app
DMG_OUTPUT  := target/$(BIN_NAME)-$(APP_VERSION)-macos-$(DMG_ARCH).dmg

all: build

frontend-install:
	cd frontend && npm install

frontend-dev:
	cd frontend && npm run dev

frontend-build: frontend-install
	cd frontend && npm run build

backend-build:
	cargo build --release

# requires frontend to be built first
backend-run:
	cargo run

build: frontend-build backend-build

run: frontend-build backend-run


test-integration:
	cargo test --test integration_test --features integration-test -- --nocapture

# Runs the integration test inside a self-contained Docker container that
# includes nostr-rs-relay and a pre-downloaded Bitcoin binary.
test-integration-docker:
	docker build -t maker-dashboard-integration-test -f docker/Dockerfile.integration-test .
	docker run --rm maker-dashboard-integration-test

# Package a double-clickable macOS .app inside a .dmg (macOS only).
# Builds the frontend + release binary, then bundles them with a launcher
# that resolves bundle-relative paths. See packaging/macos/README.md.
dmg: build
	@echo "==> Assembling $(APP_NAME).app"
	rm -rf "$(DMG_STAGING)"
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	sed -e "s/__VERSION__/$(APP_VERSION)/g" packaging/macos/Info.plist > "$(APP_BUNDLE)/Contents/Info.plist"
	cp packaging/macos/launcher.sh "$(APP_BUNDLE)/Contents/MacOS/launcher"
	chmod +x "$(APP_BUNDLE)/Contents/MacOS/launcher"
	cp target/release/$(BIN_NAME) "$(APP_BUNDLE)/Contents/MacOS/$(BIN_NAME)"
	chmod +x "$(APP_BUNDLE)/Contents/MacOS/$(BIN_NAME)"
	cp -R frontend/build/client "$(APP_BUNDLE)/Contents/Resources/frontend"
	@echo "==> Creating $(DMG_OUTPUT)"
	rm -f "$(DMG_OUTPUT)"
	hdiutil create -volname "$(APP_NAME)" -srcfolder "$(DMG_STAGING)" -ov -format UDZO "$(DMG_OUTPUT)"
	@echo "==> Done: $(DMG_OUTPUT)"

clean:
	cargo clean
	rm -rf frontend/build
	rm -rf frontend/node_modules
	rm -rf $(DMG_STAGING) $(DMG_OUTPUT)

docker-build:
	docker build -t maker-dashboard .

docker-run:
	docker run -p 3000:3000 -e MAKER_DASHBOARD_HOST=0.0.0.0 -e maker-dashboard

help:
	@echo "Maker Dashboard - Available commands:"
	@echo ""
	@echo "  make                    - Build everything (frontend + backend)"
	@echo "  make build              - Build everything (frontend + backend)"
	@echo "  make run                - Build and run the application"
	@echo ""
	@echo "Frontend:"
	@echo "  make frontend-install   - Install frontend dependencies"
	@echo "  make frontend-dev       - Run frontend dev server (hot reload)"
	@echo "  make frontend-build     - Build frontend for production"
	@echo ""
	@echo "Backend:"
	@echo "  make backend-build      - Build Rust backend"
	@echo "  make backend-run        - Run Rust backend"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build       - Build Docker image"
	@echo "  make docker-run         - Run Docker container"
	@echo ""
	@echo "Packaging:"
	@echo "  make dmg                - Build a double-clickable .app inside a .dmg (macOS only)"
	@echo ""
	@echo "Testing:"
	@echo "  make test-integration        - Run the integration test (requires nostr relay + bitcoind)"
	@echo "  make test-integration-docker - Run the integration test inside Docker (self-contained)"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean              - Clean all build artifacts"
	@echo "  make help               - Show this help message"
