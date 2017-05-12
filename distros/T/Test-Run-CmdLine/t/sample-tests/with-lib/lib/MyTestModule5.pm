use strict;

sub camel_case
{
    return join("", (map { ucfirst($_) } @_));
}

1;

