package MyHello;

use strict;

sub return_hello
{
    my $arg = shift;
    return [$arg, "hello"];
}

1;
