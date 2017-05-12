use strict;
use warnings;

use Test::More;
use Text::CSV::Auto qw( slurp_csv );
use Test::Exception;

dies_ok(
    sub{ slurp_csv('t/people.csv',{headers=>['foo','bar']}) },
    'die()s when header count does not match row',
);

my $rows = slurp_csv('t/people.csv',{headers=>['foo','bar','zot','zam']});

is_deeply(
    [ sort keys %{ $rows->[0] } ],
    [ 'bar', 'foo', 'zam', 'zot' ],
    'headers were used',
);

done_testing;
