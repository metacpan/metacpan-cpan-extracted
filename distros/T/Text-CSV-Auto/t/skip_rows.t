use strict;
use warnings;

use Test::More;
use Text::CSV::Auto qw( slurp_csv );

my $expected_ids = [
    map { $_->{feature_id} }
    @{ slurp_csv('t/features.csv',{max_rows=>5}) }
];

splice( @$expected_ids, 1, 2 );

my $ids = [
    map { $_->{feature_id} }
    @{ slurp_csv('t/features.csv',{max_rows=>5, skip_rows=>[3,4]}) }
];

is_deeply(
    $ids,
    $expected_ids,
    'skipped 2 rows',
);

done_testing;
