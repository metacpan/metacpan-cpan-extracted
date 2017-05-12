package My::Module2;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw(foo bar oops);

sub foo {
    return "foo";
}

sub bar {
    return "bar";
}

sub oops {
    return "oops";
}

1;
