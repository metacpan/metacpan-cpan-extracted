use Test::More tests => 11;
use_ok('Tie::NetAddr::IP');

my %WhereIs;
tie %WhereIs, Tie::NetAddr::IP;

$WhereIs{"0.0.0.0/0"} = "0.0.0.0/0";
$WhereIs{"10.0.0.0/8"} = "10.0.0.0/8";
$WhereIs{"20.0.0.0/8"} = "20.0.0.0/8";

is(scalar keys %WhereIs, 3);

while (my($key, $value) = each %WhereIs)
{
    is($key, $value);
}

delete $WhereIs{"10.0.0.0/8"};

is(scalar keys %WhereIs, 2);

while (my($key, $value) = each %WhereIs)
{
    is($key, $value);
}

delete $WhereIs{"20.0.0.0/8"};

is(scalar keys %WhereIs, 1);

while (my($key, $value) = each %WhereIs)
{
    is($key, $value);
}

delete $WhereIs{"0.0.0.0/0"};

is(scalar keys %WhereIs, 0);
