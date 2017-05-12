#!perl -T

use strict;
use warnings;

use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage" if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage" if $@;

my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };

plan tests => 13;

pod_coverage_ok('App::Rgit');

pod_coverage_ok('App::Rgit::Command');
pod_coverage_ok('App::Rgit::Command::Each', $trustparents);
pod_coverage_ok('App::Rgit::Command::Once', $trustparents);

pod_coverage_ok('App::Rgit::Config');
pod_coverage_ok('App::Rgit::Config::Default', $trustparents);

pod_coverage_ok('App::Rgit::Guard');

pod_coverage_ok('App::Rgit::Policy');
pod_coverage_ok('App::Rgit::Policy::Default',     $trustparents);
pod_coverage_ok('App::Rgit::Policy::Interactive', $trustparents);
pod_coverage_ok('App::Rgit::Policy::Keep',        $trustparents);

pod_coverage_ok('App::Rgit::Repository');

pod_coverage_ok('App::Rgit::Utils');
