use strict;
use warnings;

use Test::More;
use Text::CSV::Auto qw( slurp_csv );

my $formatted_rows = slurp_csv('t/people.csv');

is_deeply(
    [ sort keys %{ $formatted_rows->[0] } ],
    [ 'age', 'birth_date', 'gender', 'name' ],
    'headers formatted well',
);

my $unformatted_rows = slurp_csv('t/people.csv',{format_headers=>0});

is_deeply(
    [ sort keys %{ $unformatted_rows->[0] } ],
    [ sort ('_nAME', 'Age ', 'gender', 'BIRTH DATE') ],
    'headers were not formatted',
);

done_testing;
