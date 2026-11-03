#!/bin/bash

# Adapted from MistKit's Scripts/lint.sh, without the LINT_REPORT mode.
# Runs swift-format, SwiftLint, a build, the header check and periphery.

ERRORS=0

run_command() {
	"$@" || ERRORS=$((ERRORS + 1))
}

if [ "$LINT_MODE" = "INSTALL" ] || [ "$LINT_MODE" = "NONE" ]; then
	exit
fi

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PACKAGE_DIR="${SRCROOT:-${SCRIPT_DIR}/..}"

# Ensure mise-managed tools are on PATH outside CI (CI uses jdx/mise-action).
if command -v mise >/dev/null 2>&1 && [ -z "$CI" ] \
	&& [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	eval "$(mise -C "$PACKAGE_DIR" env -s bash)"
fi

if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
	RUN_SWIFTLINT=0
else
	RUN_SWIFTLINT=1
fi

SWIFTFORMAT_FORMAT_OPTIONS="--configuration .swift-format"
SWIFTFORMAT_LINT_OPTIONS="--configuration .swift-format --strict"

pushd "$PACKAGE_DIR" >/dev/null || exit

if [ -z "$CI" ]; then
	run_command swift-format format $SWIFTFORMAT_FORMAT_OPTIONS --recursive --parallel --in-place Sources Tests
	if [ "$RUN_SWIFTLINT" -eq 1 ]; then
		run_command swiftlint --fix
	fi
fi

if [ -z "$FORMAT_ONLY" ]; then
	run_command swift-format lint --recursive --parallel $SWIFTFORMAT_LINT_OPTIONS Sources Tests
	if [ "$RUN_SWIFTLINT" -eq 1 ]; then
		run_command swiftlint lint --strict
	fi
	run_command swift build --build-tests
fi

"$PACKAGE_DIR/Scripts/header.sh" -d "$PACKAGE_DIR/Sources" -c "Leo Dion" -o "BrightDigit" -p "ExpertHappiness"
"$PACKAGE_DIR/Scripts/header.sh" -d "$PACKAGE_DIR/Tests" -c "Leo Dion" -o "BrightDigit" -p "ExpertHappiness"

periphery_index_store() {
	local candidate
	for candidate in "$PACKAGE_DIR"/.build/*/debug/index/store \
		"$PACKAGE_DIR"/.build/debug/index/store \
		"$PACKAGE_DIR"/.build/out; do
		if [ -d "$candidate/v5/units" ]; then
			printf '%s\n' "$candidate"
			return 0
		fi
	done
	return 1
}

if [ -z "$FORMAT_ONLY" ] && [ -z "$CI" ] && [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	if INDEX_STORE_PATH=$(periphery_index_store); then
		run_command periphery scan --strict \
			--index-store-path "$INDEX_STORE_PATH" --skip-build --disable-update-check
	else
		echo "Skipping periphery scan (no index store under .build; run swift build first)."
	fi
fi

popd >/dev/null

if [ $ERRORS -gt 0 ]; then
	echo "Linting completed with $ERRORS error(s)"
	exit 1
fi
echo "Linting completed successfully"
