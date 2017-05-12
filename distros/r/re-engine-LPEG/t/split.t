use strict;
use Test::More tests => 5;
use re::engine::LPEG;

# The " " special case
{
    my ($a, $b, $c, $d, $e) = split " ", " foo bar  zar ";
    is($a, "foo");
    is($b, "bar");
    is($c, "zar");
    is($d, "");
    is($e, undef);
}

