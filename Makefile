.PHONY: help build test lint generate clean

help:
	@echo "Available targets:"
	@echo "  build     - Build the package"
	@echo "  test      - Run the test suite"
	@echo "  lint      - Run swift-format + swiftlint + periphery via Scripts/lint.sh"
	@echo "  generate  - Regenerate Sources/AppStoreConnectOpenAPI from openapi.json"
	@echo "  clean     - Clean build artifacts"
	@echo ""
	@echo "Tooling is pinned in mise.toml. Run 'mise install' once."

build:
	swift build

test:
	swift test

lint:
	@mise exec -- ./Scripts/lint.sh

generate:
	@./Scripts/generate-openapi.sh

clean:
	swift package clean
