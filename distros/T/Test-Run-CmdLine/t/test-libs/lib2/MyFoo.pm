package MyFoo;

use strict;

sub return_foo
{
    my $arg = shift;
    return [$arg, "foo"];
}

1;

