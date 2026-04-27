# BEIE Nexus Development Makefile
# Run common development tasks with `make <target>`

.PHONY: help install dev dev-api build test lint typecheck clean docker-up docker-down db-migrate db-seed docs

# Default target
help: ## Show this help message
	@echo "BEIE Nexus Development Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# =============================================================================
# INSTALLATION & SETUP
# =============================================================================

install: ## Install all dependencies
	bun install

setup: ## Initial project setup
	bun install
	cp .env.example .env
	@echo "Please edit .env with your configuration"

# =============================================================================
# DEVELOPMENT
# =============================================================================

dev: ## Start Next.js development server
	bun run dev

dev-api: ## Start API Gateway development server
	bun run dev:api

dev-all: ## Start all services (requires Docker)
	docker-compose -f docker-compose.dev.yml up -d
	bun run dev &
	bun run dev:api &
	@echo "Services starting... Check individual terminals for logs"

# =============================================================================
# BUILDING
# =============================================================================

build: ## Build all packages and apps
	bun run build

build-ui: ## Build UI package
	bun run build:ui

build-api: ## Build API Gateway
	bun run build:api

# =============================================================================
# TESTING
# =============================================================================

test: ## Run all tests
	bun run test

test-watch: ## Run tests in watch mode
	bun run test:watch

test-coverage: ## Run tests with coverage
	bun run test:coverage

test-e2e: ## Run end-to-end tests
	bun run test:e2e

# =============================================================================
# QUALITY
# =============================================================================

lint: ## Run linting
	bun run lint

lint-fix: ## Run linting with auto-fix
	bun run lint:fix

typecheck: ## Run TypeScript type checking
	bun run typecheck

format: ## Format code with Prettier
	bun run format

quality: lint typecheck test ## Run all quality checks

# =============================================================================
# DATABASE
# =============================================================================

db-migrate: ## Run database migrations
	@echo "Running database migrations..."
	# Add your migration command here

db-seed: ## Seed database with test data
	@echo "Seeding database..."
	# Add your seed command here

db-reset: ## Reset database (WARNING: destroys data)
	@echo "Resetting database..."
	# Add your reset command here

# =============================================================================
# DOCKER
# =============================================================================

docker-up: ## Start all Docker services
	docker-compose -f docker-compose.dev.yml up -d

docker-down: ## Stop all Docker services
	docker-compose -f docker-compose.dev.yml down

docker-logs: ## Show Docker logs
	docker-compose -f docker-compose.dev.yml logs -f

docker-clean: ## Remove all Docker containers and volumes
	docker-compose -f docker-compose.dev.yml down -v --remove-orphans

# =============================================================================
# INFRASTRUCTURE
# =============================================================================

infra-plan: ## Plan Terraform changes
	cd infrastructure/terraform && terraform plan

infra-apply: ## Apply Terraform changes
	cd infrastructure/terraform && terraform apply

infra-destroy: ## Destroy Terraform infrastructure
	cd infrastructure/terraform && terraform destroy

# =============================================================================
# AI/ML
# =============================================================================

ai-train: ## Train AI models
	@echo "Training AI models..."
	# Add your training commands here

ai-test: ## Test AI services
	@echo "Testing AI services..."
	# Add your AI test commands here

# =============================================================================
# BLOCKCHAIN
# =============================================================================

blockchain-deploy: ## Deploy smart contracts
	@echo "Deploying smart contracts..."
	# Add your deployment commands here

blockchain-test: ## Test smart contracts
	@echo "Testing smart contracts..."
	# Add your contract test commands here

# =============================================================================
# MONITORING
# =============================================================================

monitor-up: ## Start monitoring stack
	docker-compose -f infrastructure/docker/monitoring/docker-compose.yml up -d

monitor-down: ## Stop monitoring stack
	docker-compose -f infrastructure/docker/monitoring/docker-compose.yml down

# =============================================================================
# DOCUMENTATION
# =============================================================================

docs-build: ## Build documentation
	@echo "Building documentation..."
	# Add documentation build commands

docs-serve: ## Serve documentation locally
	@echo "Serving documentation..."
	# Add documentation serve commands

docs-deploy: ## Deploy documentation
	@echo "Deploying documentation..."
	# Add documentation deployment commands

# =============================================================================
# UTILITIES
# =============================================================================

clean: ## Clean build artifacts and caches
	rm -rf node_modules/.cache
	rm -rf .next
	rm -rf dist
	rm -rf coverage
	rm -rf .turbo

clean-all: clean docker-clean ## Clean everything including Docker

deps-update: ## Update all dependencies
	bun update

deps-audit: ## Audit dependencies for security issues
	bun audit

# =============================================================================
# CI/CD SIMULATION
# =============================================================================

ci: quality build test-e2e ## Run full CI pipeline locally

# =============================================================================
# DEVELOPMENT WORKFLOWS
# =============================================================================

new-phase: ## Start a new development phase
	@echo "Starting new phase..."
	@read -p "Phase number: " phase; \
	read -p "Phase description: " desc; \
	git checkout -b "phase/$$phase-$$desc"; \
	echo "Created branch: phase/$$phase-$$desc"

pr-create: ## Create a pull request for current branch
	@echo "Creating pull request..."
	@branch=$$(git branch --show-current); \
	phase=$$(echo $$branch | sed 's/phase\///' | cut -d- -f1); \
	desc=$$(echo $$branch | sed 's/phase\/[0-9]*-//'); \
	gh pr create --title "Phase $$phase: $$desc" --body "Implementation of phase $$phase: $$desc" --base main --head $$branch

release: ## Create a new release
	@echo "Creating release..."
	@read -p "Version (e.g., v1.0.0): " version; \
	read -p "Release notes: " notes; \
	git tag -a $$version -m "$$notes"; \
	git push origin $$version; \
	gh release create $$version --title "$$version" --notes "$$notes"

# =============================================================================
# HELPERS
# =============================================================================

.PHONY: print-%
print-%: ## Print the value of a make variable
	@echo '$*=$($*)'

.PHONY: guard-%
guard-%: ## Guard clause for required variables
	@if [ -z '${${*}}' ]; then echo 'ERROR: variable $* not set' && exit 1; fi