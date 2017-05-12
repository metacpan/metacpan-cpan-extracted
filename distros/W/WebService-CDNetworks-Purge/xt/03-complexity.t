#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin;
use File::Spec;
use File::Basename qw(dirname);
use Perl::Metrics::Simple;

my $MAX_COMPLEXITY = 10;

my $module   = File::Spec -> catfile(dirname($FindBin::RealBin), 'lib/WebService/CDNetworks/Purge.pm');
my $metrics  = Perl::Metrics::Simple -> new();
my $analysis = $metrics -> analyze_files($module);

my @subs = @{$analysis->subs()};
foreach my $sub (@subs) {
	my $test_msg = sprintf('Complexity: %2d, method: %s', $sub -> {'mccabe_complexity'}, $sub -> {'name'});
	ok($sub -> {'mccabe_complexity'} <= $MAX_COMPLEXITY, $test_msg);
}

done_testing( scalar @subs );

