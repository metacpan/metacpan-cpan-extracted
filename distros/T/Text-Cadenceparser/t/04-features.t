#!/usr/bin/perl
#
# Copyright (C) 2012 by Lieven Hollevoet

# Verify features that were added

use strict;
use Test::More;
use Test::Output;
use Data::Dumper;

use_ok 'Text::Cadenceparser';

# Test parsing of final.rtp for regular flows
my $parser = Text::Cadenceparser->new(folder => 't/stim/FINAL');
my $files_parsed = $parser->{_files_parsed};
is $files_parsed, 1, 'Found report file for regular rpt';
is $parser->get_final('Memory (MB)'), '256.00', "Extracted final report value regular flow correctly";
is $parser->get_final('bliebelblabbel'), undef, "Non-existent value correctly reports as being undefined";

# Test parsing for physical flows too
$parser = Text::Cadenceparser->new(folder => 't/stim/PHYSICAL');
$files_parsed = $parser->{_files_parsed};
is $files_parsed, 1, 'Found report file for physical rpt';
is $parser->get_final('Memory (MB)'), '266.00', "Extracted final report value physical flow correctly";

# Output for equally-contributing units should be sorted alphabetically
$parser = Text::Cadenceparser->new(key => 'area', 'area_rpt' => 't/stim/area_100.rpt', 'power_rpt' => 't/stim/power_100_nop.rpt', 'threshold' => 5);
ok $parser, 'object created';

stdout_like { $parser->report() }  qr/vu1_mul.+\n.+vu2_mul/, 'Check sorting';

# Ensure we have a separate part reporting the toplevel logic
$parser = Text::Cadenceparser->new(key => 'area', 'area_rpt' => 't/stim/area_100.rpt', 'threshold' => 0.00005);
stdout_like {$parser->report() } qr/toplevel/, 'Toplevel reported';

# Test non-verbose power output parsing
$parser = Text::Cadenceparser->new(key => 'active', power_rpt => 't/stim/non_verbose_power');
ok $parser, 'object created';

stdout_like {$parser->report() } qr/Total active : 45.125/, 'Non-verbose input format verified correctly';

# Test verbose power output parsing
$parser = Text::Cadenceparser->new(key => 'active', power_rpt => 't/stim/verbose_power');
ok $parser, 'object created';

stdout_like {$parser->report() } qr/Total active : 45.125/, 'Non-verbose input format verified correctly';

done_testing();
