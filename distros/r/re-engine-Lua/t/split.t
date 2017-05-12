use strict;
use Test::More tests => 17;
use re::engine::Lua;

{
    my ($a, $b, $c) = split /(:)/, "a:b";
    is($a, "a");
    is($b, ":");
    is($c, "b");
}

# The " " special case
{
    my ($a, $b, $c, $d, $e) = split " ", " foo bar  zar ";
    is($a, "foo");
    is($b, "bar");
    is($c, "zar");
    is($d, "");
    is($e, undef);
}

# The /%s+/ special case
{
    my ($a, $b, $c, $d) = split /%s+/, "a b  c\t d";
    is($a, "a");
    is($b, "b");
    is($c, "c");
    is($d, "d");
}

# / /, not a special case
{
    my ($a, $b, $c, $d, $e) = split / /, " x y ";
    is($a, "");
    is($b, "x");
    is($c, "y");
    is($d, "");
    is($e, undef);
}
