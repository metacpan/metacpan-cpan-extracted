use Test::Most;

use lib 'lib';
use Unknown::Values;

ok !( 1 == unknown ), 'Direct comparisons to unknown should fail (==)';
ok !( unknown == unknown ), '... and unknown should not be == to itself';
ok !( unknown eq unknown ), '... and unknown should not be eq to itself';
ok !( 2 <= unknown ), 'Direct comparisons to unknown should fail (<=)';
ok !( 3 >= unknown ), 'Direct comparisons to unknown should fail (>=)';
ok !( 4 > unknown ), 'Direct comparisons to unknown should fail (>)';
ok !( 5 < unknown ), 'Direct comparisons to unknown should fail (<)';
ok !( 6 != unknown ),
  'Direct negative comparisons to unknown should fail (!=)';
ok !( 6 ne unknown ),
  'Direct negative comparisons to unknown should fail (ne)';
ok !( unknown ne unknown ),
  'Negative comparisons of unknown to unknown should fail (ne)';

my $value   = unknown;
my @array   = ( 1, 2, 3, $value, 4, 5 );
my @less    = grep { $_ < 4 } @array;
my @greater = grep { $_ > 3 } @array;
eq_or_diff \@less, [ 1, 2, 3 ], 'unknown values are not returned with <';
eq_or_diff \@greater, [ 4, 5 ], 'unknown values are not returned with >';
eq_or_diff [ grep { is_unknown $_ } @array ], [unknown],
  '... but you can look for unknown values';

my @sorted = sort { $a <=> $b } ( 4, 1, unknown, 5, unknown, unknown, 7 );
eq_or_diff \@sorted, [ 1, 4, 5, 7, unknown, unknown, unknown ],
  'Unknown values should sort at the end of the list';
@sorted = sort { $b <=> $a } ( 4, 1, unknown, 5, unknown, unknown, 7 );
eq_or_diff \@sorted, [ unknown, unknown, unknown, 7, 5, 4, 1 ],
  '... but the sort to the front in reverse';

{
    local $_ = unknown;
    ok is_unknown, 'is_unknown() defaults to $_';
    local $_ = undef;
    ok !is_unknown, '... and knows that undef is not unknown';
}

done_testing;
