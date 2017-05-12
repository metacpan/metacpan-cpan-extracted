#!/usr/bin/perl
#
# Copyright (C) 2012 by Lieven Hollevoet

# Verify bugs that were reported by users

use strict;
use Test::More;
use Test::Output;
use Test::Exception;

use_ok 'Text::Cadenceparser';

# Test very small thresholds don't throw errors
my $parser = Text::Cadenceparser->new(key => 'area', 'area_rpt' => 't/stim/area_100.rpt', 'power_rpt' => 't/stim/power_100_nop.rpt', 'threshold' => 0.0001);
ok $parser, 'object created';

stderr_unlike { $parser->report() }  qr/uninitialized/, 'Check small threshold';

# Ensure we don't end up with warnings when a user passes an empty power file
throws_ok { $parser = Text::Cadenceparser->new(key => 'active', 'area_rpt' => 't/stim/area_100.rpt', 'power_rpt' => 't/stim/empty.rpt')
 } qr/please check/, 'Gracefully handle empty power file';


done_testing();
