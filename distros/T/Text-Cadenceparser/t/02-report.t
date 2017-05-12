#!/usr/bin/perl
#
# Copyright (C) 2012 by Lieven Hollevoet

# Verify the report generator functionality
# this is typically used after power simulations have been run
# or to get area reporting after synthesis
use strict;
use Test::More tests => 7;

use_ok 'Text::Cadenceparser';

my $parser = Text::Cadenceparser->new(key => 'area', 'area_rpt' => 't/stim/area_100.rpt', 'power_rpt' => 't/stim/power_100_nop.rpt');
ok $parser, 'object created';

my $count = scalar($parser->files_parsed());
is $count, 2, "... area report parsed";

my $total = $parser->get('area');
is $total, 628052, "... total area matches";

my $threshold = $parser->get('threshold');
is $threshold, 1, "... threshold defaults to one";

$parser = Text::Cadenceparser->new(key => 'area', 'area_rpt' => 't/stim/area_100.rpt', 'power_rpt' => 't/stim/power_100_nop.rpt', 'threshold' => 2);
ok $parser, 'object created';

$threshold = $parser->get('threshold');
is $threshold, 2, "... could pass a value to threshold";
