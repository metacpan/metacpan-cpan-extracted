#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

undef $@;
eval "blessed('')";
like($@, qr/^Undefined subroutine &main::blessed called/);

{
    use lexically 'Scalar::Util', 'blessed';
    ok(blessed(bless {}));
    ok(!blessed([]));
}

undef $@;
eval "blessed('')";
like($@, qr/^Undefined subroutine &main::blessed called/);

done_testing;
