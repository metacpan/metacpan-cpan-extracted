use 5.006;
use strict;
use warnings;
use Test::More 0.96;

use Try::Tiny::Retry qw/:all/;
$Try::Tiny::Retry::_DEFAULT_DELAY = 10; # shorten default delay

subtest 'default_exp' => sub {
    my $count  = 0;
    my $caught = '';
    my @err;
    retry {
        pass("try $count");
        die "ick" if ++$count < 13;
    }
    delay_exp { 3, 10 } catch {
        $caught = $_;
    };
    is( $count, 3, "correct number of retries" );
    like( $caught, qr/^ick/, "caught exception when retries failed" );
};

subtest 'custom delay function' => sub {
    my $count  = 0;
    my $caught = '';
    my @err;
    retry {
        pass("try $count");
        die "ick" if ++$count < 6;
    }
    delay {
        my $c = shift;
        return if $c >= 3;
        return 1; # not really a delay
    }
    catch {
        $caught = $_;
    };
    is( $count, 3, "correct number of retries" );
    like( $caught, qr/^ick/, "caught exception when retries failed" );
};

subtest 'repeating delay is fatal' => sub {
    eval {
        retry { fail("shouldn't run") }
        delay_exp { 3, 10 } delay { return if shift() >= 2; sleep 1 };
    };
    like( $@, qr/may not be followed by multiple delay/, "caught expected exception" );
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
