use 5.006;
use strict;
use warnings;
use Test::More 0.96;

use Try::Tiny::Retry qw/:all/;
$Try::Tiny::Retry::_DEFAULT_DELAY = 10; # shorten default delay

subtest 'default retry and fail' => sub {
    my $count        = 0;
    my $caught       = '';
    my $on_retry     = 0;
    my $on_retry_err = '';
    retry {
        pass("try $count");
        die "ick" if ++$count < 13;
    }
    on_retry {
        $on_retry_err = $_;
        $on_retry++;
    }
    catch {
        $caught = $_;
    };
    is( $count,    10, "correct number of retries" );
    is( $on_retry, 9,  "correct number of on_retry blocks run" );
    like( $caught,       qr/^ick/, "caught exception when retries failed" );
    like( $on_retry_err, qr/^ick/, "on_retry has error in \$_" );
};

subtest 'default retry and succeed' => sub {
    my $count    = 0;
    my $caught   = '';
    my $on_retry = 0;
    retry {
        pass("try $count");
        die "ick" if ++$count < 6;
    }
    on_retry {
        $on_retry++;
    }
    catch {
        $caught = $_;
    };
    is( $count,    6,  "correct number of retries" );
    is( $on_retry, 5,  "correct number of on_retry blocks run" );
    is( $caught,   "", "no exceptions caught" );
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
