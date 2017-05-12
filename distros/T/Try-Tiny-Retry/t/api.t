use 5.006;
use strict;
use warnings;
use Test::More 0.96;

subtest "default exports" => sub {

    package WantDefaultExports;
    use Try::Tiny::Retry;
    for my $f (qw/retry retry_if try catch finally/) {
        Test::More::can_ok( __PACKAGE__, $f );
    }
};

subtest "all exports" => sub {

    package WantAllExports;
    use Try::Tiny::Retry ':all';
    for my $f (qw/retry retry_if delay delay_exp try catch finally/) {
        Test::More::can_ok( __PACKAGE__, $f );
    }
};

done_testing;
#
# This file is part of Try-Tiny-Retry
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: ts=4 sts=4 sw=4 et:
