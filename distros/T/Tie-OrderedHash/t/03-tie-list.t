#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# tie %h, 'Tie::OrderedHash', LIST -- the trailing list is treated
# as key/value pairs, in source order.  Same as Tie::IxHash.

tie my %h, 'Tie::OrderedHash', a => 1, b => 2, c => 3;
is_deeply([keys %h],   [qw(a b c)], 'tie LIST: keys in source order');
is_deeply([values %h], [1, 2, 3],   'tie LIST: values match');
is(scalar keys %h, 3,                'tie LIST: count');

# Empty list also works.
tie my %g, 'Tie::OrderedHash';
is(scalar keys %g, 0, 'tie no-list: empty');

# Odd-count list croaks.
eval { tie my %bad, 'Tie::OrderedHash', 'lonely' };
like($@, qr/odd number of arguments/i, 'odd-count list croaks');

done_testing;
