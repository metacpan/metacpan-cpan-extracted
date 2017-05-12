use warnings;
use strict;

use Test::More tests => 12;

{my ($i, $msg) = qw(0 test);
sub t {
    return ($msg, $i) = (@_, 0) if @_;
    $msg.' '.++$i
}}

use here 'my $x = 5';

t 'here my';
ok eval '$x', t;
ok !$@, t;
is eval '$x', 5, t;


use here '{';
my $y = 3;
use here '}';

t 'here syntax';
ok !eval '$y', t;
ok $@, t;

sub myok {
    map {"my \$$_ = 'ok';"} @_
}

t 'here transform';
{
    use here myok qw(x y z);
    is eval '$x', 'ok', t;
    is eval '$y', 'ok', t;
    is eval '$z', 'ok', t;
}


t 'use here::install';

use here::install myok => \&myok;

{
    use myok qw(a b);

    is eval '$a', 'ok', t;
    is eval '$b', 'ok', t;
}

no here::install 'myok';

BEGIN {
    t 'no here::install'; {
        ok !$INC{'myok.pm'}, t;
        ok !defined &myok::import, t;
    }
}
