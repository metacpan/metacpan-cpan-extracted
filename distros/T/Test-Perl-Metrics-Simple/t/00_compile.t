use strict;
use warnings;
use Test::More tests => 5;

#-----------------------------------------------------------------------------

use_ok('Test::Perl::Metrics::Simple');
can_ok('Test::Perl::Metrics::Simple', 'metrics_ok');
can_ok('Test::Perl::Metrics::Simple', 'all_metrics_ok');
can_ok('Test::Perl::Metrics::Simple', '_all_code_files');
can_ok('Test::Perl::Metrics::Simple', '_starting_points');
