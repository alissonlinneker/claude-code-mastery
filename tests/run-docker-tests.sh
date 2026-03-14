#!/usr/bin/env bash
# Claude Code Mastery — Docker Integration Test Runner
# Builds and runs integration tests in isolated containers.
#
# Usage: bash tests/run-docker-tests.sh [environment]
# Examples:
#   bash tests/run-docker-tests.sh              # Run all environments
#   bash tests/run-docker-tests.sh ubuntu-bash   # Run specific environment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$SCRIPT_DIR/docker"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Check Docker is available
if ! command -v docker &>/dev/null; then
  echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
  exit 1
fi

ENVIRONMENTS=("ubuntu-bash" "ubuntu-zsh" "alpine")
SELECTED="${1:-all}"
PASS=0
FAIL=0

echo ""
echo -e "${BOLD}┌──────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}│  Claude Code Mastery — Docker Integration Tests  │${NC}"
echo -e "${BOLD}└──────────────────────────────────────────────────┘${NC}"
echo ""

for env in "${ENVIRONMENTS[@]}"; do
  if [ "$SELECTED" != "all" ] && [ "$SELECTED" != "$env" ]; then
    continue
  fi

  DOCKERFILE="$DOCKER_DIR/Dockerfile.$env"
  if [ ! -f "$DOCKERFILE" ]; then
    echo -e "${YELLOW}[SKIP]${NC} $env — Dockerfile not found"
    continue
  fi

  IMAGE_NAME="ccm-test-$env"

  echo -e "${BOLD}[$env]${NC} Building image..."
  if docker build -t "$IMAGE_NAME" -f "$DOCKERFILE" "$REPO_DIR" --quiet > /dev/null 2>&1; then
    echo -e "${BOLD}[$env]${NC} Running tests..."
    if docker run --rm "$IMAGE_NAME" 2>&1; then
      echo -e "${GREEN}[PASS]${NC} $env"
      PASS=$((PASS + 1))
    else
      echo -e "${RED}[FAIL]${NC} $env"
      FAIL=$((FAIL + 1))
    fi
  else
    echo -e "${RED}[FAIL]${NC} $env — Docker build failed"
    FAIL=$((FAIL + 1))
  fi

  # Clean up image
  docker rmi "$IMAGE_NAME" --force > /dev/null 2>&1 || true
  echo ""
done

echo "══════════════════════════════════════════════════"
echo ""
TOTAL=$((PASS + FAIL))

if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}All $TOTAL environments passed.${NC}"
else
  echo -e "${RED}$FAIL/$TOTAL environments failed.${NC}"
fi

echo ""
exit "$FAIL"
