# SPDX-License-Identifier: MIT
use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Test::SPDX::Coverage') };

ok(defined(&spdx_coverage_ok), 'exported spdx_coverage_ok');
