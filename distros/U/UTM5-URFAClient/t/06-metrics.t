use strict;
use warnings;

use File::Spec;
use Test::More;

unless($ENV{RELEASE_TESTING}) {
    plan skip_all => 'Author tests not required for installation';
}

eval 'use Test::Perl::Metrics::Simple';
plan skip_all => 'Module Test::Perl::Metrics::Simple required for criticise test' if $@;

Test::Perl::Metrics::Simple->import(-complexity => 30);
all_metrics_ok();