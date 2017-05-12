use strict;
use warnings;

use Test::More tests => 2;
use Validate::Tiny ':all';

my $r = {
    fields => ['a'],
    checks => [
        a => [
            sub {
                my ( $val, $param, $key ) = @_;
                $param->{$key} == $val ? undef : 'Err';
            }
        ]
    ]
};

my ($i, $o);

$i = { a => 4 };
$o = validate( $i, $r );
ok $o->{success};
is $o->{data}->{a}, 4;
