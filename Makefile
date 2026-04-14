# =============================================================================
# UsageBar - Development Makefile
# =============================================================================

.PHONY: setup lint lint-swift lint-actions help

ACTION_VALIDATOR := ./node_modules/.bin/action-validator

# Default target
help:
	@echo "Available commands:"
	@echo "  make setup        - Configure git hooks (run once after clone)"
	@echo "  make lint         - Run all linters"
	@echo "  make lint-swift   - Run SwiftLint only"
	@echo "  make lint-actions - Run action-validator only"

# =============================================================================
# Setup - Run once after cloning
# =============================================================================
setup:
	@echo "Configuring git hooks..."
	@git config core.hooksPath .githooks
	@echo "✓ Git hooks configured"
	@echo ""
	@echo "Pre-commit will now run:"
	@echo "  - SwiftLint on .swift files"
	@echo "  - action-validator on .github/workflows/*.yml files"

# =============================================================================
# Linting
# =============================================================================
lint: lint-swift lint-actions

lint-swift:
	@echo "Running SwiftLint..."
	@swiftlint lint CopilotMonitor/CopilotMonitor

lint-actions:
	@echo "Running action-validator..."
	@test -x "$(ACTION_VALIDATOR)" || (echo "action-validator not found. Run: npm install" && exit 1)
	@for f in .github/workflows/*.yml; do \
		echo "Validating $$f..."; \
		"$(ACTION_VALIDATOR)" "$$f"; \
	done
