use 5.006;
use strict;
use warnings;
use Test::More 0.96;

use Try::Tiny::Retry qw/:all/;
$Try::Tiny::Retry::_DEFAULT_DELAY = 10; # shorten default delay

subtest 'scalar context' => sub {
    my $result = retry {
        my @array = 1 .. 10;
        return @array;
    };
    is( $result, 10, "correct result from retry block" );
};

subtest 'list context' => sub {
    my @result = retry {
        my @array = 1 .. 10;
        return @array;
    };
    is_deeply( \@result, [ 1 .. 10 ], "correct result from retry block" );
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
