#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my $success = eval <<EOF;
no circular::require;

{
    package Foo;
    sub bar {}
}

{
    package Bar;
    use base 'Foo';
}
1;
EOF

my $e = $@;

ok($success, "no error with use base")
    || diag($e);

done_testing;
