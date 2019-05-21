use strict;
use warnings;

use WebDriver::Tiny::Elements;
use Test::More tests => 15;

sub make { bless [ 'd', @_ ], 'WebDriver::Tiny::Elements' }

my $e = make( 1 .. 9 );

is_deeply $e->first, [ 'd', 1 ], '->first';

is_deeply $e->last, [ 'd', 9 ], '->last';

is $e->size, 9, '->size';

is_deeply $e->slice(-2), [ 'd', 8 ], '->slice(-2)';

is_deeply $e->slice(-1), [ 'd', 9 ], '->slice(-1)';

is_deeply $e->slice(0), [ 'd', 1 ], '->slice(0)';

is_deeply $e->slice(5), [ 'd', 6 ], '->slice(5)';

is_deeply $e->slice(9), [ 'd', undef ], '->slice(9)';

is_deeply $e->slice( -1, 0, 1, 3, 7, 12 ), [ 'd', 9, 1, 2, 4, 8, undef ],
    '->slice( -1, 0, 1, 3, 7, 12 )';

my $no_e = make();
is_deeply [ $no_e->split ], [], '->split [no elements]';

my $one_e = make(1);
is_deeply [ $one_e->split ], [ [ 'd', 1 ] ], '->split [one element]';

is_deeply [ $e->split ],
    [
    [ 'd', 1 ], [ 'd', 2 ], [ 'd', 3 ], [ 'd', 4 ], [ 'd', 5 ], [ 'd', 6 ],
    [ 'd', 7 ], [ 'd', 8 ], [ 'd', 9 ],
    ],
    '->split [multiple elements]';

is_deeply $e->append( make( 10, 11 ), make(12) ), [ 'd', 1 .. 12 ],
    '->append';

is_deeply [ sort @{ $e->append( make( 6, 9 ) )->uniq } ], [ 1 .. 9, 'd' ], '->uniq';

is_deeply $e, [ 'd', 1 .. 9 ], 'Original is unaffected';
