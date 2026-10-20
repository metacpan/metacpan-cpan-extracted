use strict;
use warnings;
use Test::More;
use lib 'lib';

use Test::FitNesse::Slim;
use Test::FitNesse::Slim::ConverterRegistry;
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::ListExecutor;
use Test::FitNesse::Slim::MapResult;
use Test::FitNesse::Slim::Server;
use Test::FitNesse::Slim::SlimHelperLibrary;
use Test::FitNesse::Slim::Statement;
use Test::FitNesse::Slim::StatementExecutor;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

all_pod_coverage_ok();
