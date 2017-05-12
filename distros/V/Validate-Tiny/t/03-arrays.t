
use strict;
use warnings;

use Test::More tests => 2;
use Validate::Tiny ':all';

my $f = sub {
    [ grep { $_ > 2 } @{ $_[0] } ];
};

my $c = sub {
    for ( @{ $_[0] } ) { return 'Error' if $_ > 5 }
    undef;
};

my $r = { fields => ['a'], filters => [ a => $f ], checks => [ a => $c ] };
my $i = { a => [ 1, 2, 3, 4 ] };
my $o = { success => 1, data => { a => [ 3, 4 ] }, error => {} };
is_deeply validate( $i, $r ), $o;

$i = { a => [ 1, 2, 3, 4, 20, 30 ] };
$o = { success => 0, data => { a => [ 3, 4, 20, 30 ] }, error => { a => 'Error' } };
is_deeply validate( $i, $r ), $o;

