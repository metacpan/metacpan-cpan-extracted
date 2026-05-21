# SPDX-License-Identifier: MIT
use Test::More tests => 1;
use Test::SPDX::Coverage;
local $@;
eval{spdx_coverage_ok({diag=>9, manifest=>'manifest.not_found.txt'})};
my $error = $@;
like($error, qr/Error: option "manifest" invalid.*File.*not found/, 'manifest File not found');
