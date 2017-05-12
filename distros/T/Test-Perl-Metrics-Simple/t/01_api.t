use strict;
use warnings;
use Test::More tests => 4;
use Test::Perl::Metrics::Simple;

#-----------------------------------------------------------------------------
# Export tests

can_ok('main', 'metrics_ok');
can_ok('main', 'all_metrics_ok');

#-----------------------------------------------------------------------------
# Test exception for missing files

eval{ metrics_ok('foobar') };
ok(defined $@);

#-----------------------------------------------------------------------------
# Test exception for null file

eval{ metrics_ok() };
ok(defined $@);
