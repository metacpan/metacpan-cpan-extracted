use strict;
use warnings;

use Test::More;
use Text::CSV::Auto qw( slurp_csv );

my $all_rows = slurp_csv('t/features.csv');
is( scalar(@$all_rows), 50, 'has 50 rows total' );

my $ten_rows = slurp_csv('t/features.csv', {max_rows=>10});
is( scalar(@$ten_rows), 9, 'limited to ten rows' );

done_testing;
