use strict;
use warnings;
use utf8;
use Test::More tests => 8;
use Test::Warn;
use Text::Ligature qw( :all );

is(
    to_ligatures('offloading floral offices refines effectiveness'),
    'oﬄoading ﬂoral oﬃces reﬁnes eﬀectiveness',
    'to ligatures'
);

is(
    from_ligatures('oﬄoading ﬂoral oﬃces reﬁnes eﬀectiveness'),
    'offloading floral offices refines effectiveness',
    'from ligatures'
);

is   to_ligatures( 'after stop' ), 'after stop', 'ligatures not in defaults';
is from_ligatures( 'aﬅer ﬆop'   ), 'after stop', 'from st-ligature';

warning_is { to_ligatures() } {
    carped => 'to_ligatures() expects one argument'
}, 'too few args passed to to_ligatures()';

warning_is { to_ligatures('foo', 'bar') } {
    carped => 'to_ligatures() expects one argument'
}, 'too many args passed to to_ligatures()';

warning_is { from_ligatures() } {
    carped => 'from_ligatures() expects one argument'
}, 'too few args passed to from_ligatures()';

warning_is { from_ligatures('foo', 'bar') } {
    carped => 'from_ligatures() expects one argument'
}, 'too many args passed to from_ligatures()';
