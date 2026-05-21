# SPDX-License-Identifier: MIT
use Test::More;
eval "use Test::SPDX::Coverage";
plan skip_all => "Test::SPDX::Coverage required for testing SPDX-License-Identifier coverage" if $@;
spdx_coverage_ok({diag=>9, lines=>1000, match=>qr/\.(?:pm|pl|cgi|t)\Z/});
