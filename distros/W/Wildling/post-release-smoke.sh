#!/bin/sh
# Post-release consumer smoke for perl (git/GitHub + registry as documented).
set -eu

LANG_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$LANG_DIR/.." && pwd)"
# shellcheck disable=SC1091
. "$ROOT/scripts/post-release-smoke-lib.sh"
post_release_smoke_init

SMOKE_FAIL=0

smoke_perl() {
    channel perl git smoke_perl_git
    channel perl registry smoke_perl_registry
}

smoke_perl_git() {
    smoke_clone_build_cli perl
    _wd="${SMOKE_ROOT}/perl-git"
    run_docker_root "perl:5.40-bookworm" "${_wd}/repo/perl" '
set -eu
cpanm --quiet --notest --installdeps . 2>/dev/null || true
perl -Ilib -MWildling -e "
my \$w = Wildling::create([\"ab\"]);
die \"count\" unless \$w->count() == 1;
die \"get\" unless \$w->get(0) eq \"ab\";
"
'
}

smoke_perl_registry() {
    _wd="$(workdir perl-registry)"
    run_docker_root "perl:5.40-bookworm" "${_wd}" '
set -eu
cpanm --quiet --notest Wildling@'"${VERSION}"' || cpanm --quiet --notest Wildling
perl -MWildling -e "
my \$w = Wildling::create([\"ab\"]);
die \"count\" unless \$w->count() == 1;
die \"get\" unless \$w->get(0) eq \"ab\";
"
# CLI if installed
if command -v wildling >/dev/null 2>&1; then
  wildling --version | grep -F "'"${VERSION}"'"
  [ "$(wildling ab)" = ab ]
fi
'
}

smoke_perl

if [ "$SMOKE_FAIL" -ne 0 ]; then
    echo "Post-release smoke failed for perl." >&2
    exit 1
fi
