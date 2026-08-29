#!/usr/bin/env bash
#
# Local quality gate. Runs fmt / validate / tflint / trivy / terraform-docs.
# Only `terraform` and `docker` need to be on PATH — the linters run as pinned
# Docker images, nothing is installed.
#
# Usage:
#   scripts/check.sh          # check everything, non-zero exit on any failure
#   scripts/check.sh --fix    # also apply `terraform fmt` and regenerate docs
#
set -uo pipefail

cd "$(dirname "$0")/.."
repo="$PWD"

TFLINT_IMAGE="ghcr.io/terraform-linters/tflint:v0.64.0"
TRIVY_IMAGE="aquasec/trivy:0.74.0"
TFDOCS_IMAGE="quay.io/terraform-docs/terraform-docs:0.20.0"

fix=0
[ "${1:-}" = "--fix" ] && fix=1

fail=0
step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

step "terraform fmt"
if [ "$fix" -eq 1 ]; then
  terraform fmt -recursive
else
  terraform fmt -check -recursive -diff || fail=1
fi

step "terraform validate"
terraform validate -compact-warnings || fail=1

step "terraform test"
terraform test || fail=1

step "tflint"
docker run --rm -v "$repo:/data" -w /data "$TFLINT_IMAGE" \
  --recursive --config=/data/.tflint.hcl || fail=1

step "trivy config"
docker run --rm -v "$repo:/data" -w /data "$TRIVY_IMAGE" \
  config --exit-code 1 . || fail=1

step "terraform-docs"
if [ "$fix" -eq 1 ]; then
  docker run --rm -v "$repo:/terraform-docs" -u "$(id -u)" "$TFDOCS_IMAGE" \
    -c /terraform-docs/.terraform-docs.yml /terraform-docs
else
  docker run --rm -v "$repo:/terraform-docs" -u "$(id -u)" "$TFDOCS_IMAGE" \
    --output-check -c /terraform-docs/.terraform-docs.yml /terraform-docs || fail=1
fi

if [ "$fail" -eq 0 ]; then
  printf '\n\033[32mAll checks passed.\033[0m\n'
else
  printf '\n\033[31mChecks failed.\033[0m Run with --fix for the auto-fixable ones.\n'
fi
exit $fail
