use 5.006;
use strict;
use warnings;
use Test::More 0.96;

use Try::Tiny::Retry qw/:all/;
$Try::Tiny::Retry::_DEFAULT_DELAY = 10; # shorten default delay

subtest 'conditional not satisfied' => sub {
    my $count  = 0;
    my $caught = '';
    my @err;
    retry {
        pass("try $count");
        $count++;
        die "ick";
    }
    retry_if { /^oops/ }
    catch {
        $caught = $_;
    };
    is( $count, 1, "correct number of retries" );
    like( $caught, qr/^ick/, "caught expected error" );
};

subtest 'conditional not satisfied' => sub {
    my $count  = 0;
    my $caught = '';
    my @err;
    retry {
        pass("try $count");
        $count++;
        die "oops" if $count < 6;
        die "ick"  if $count >= 6;
    }
    retry_if { /^oops/ }
    catch {
        $caught = $_;
    };
    is( $count, 6, "correct number of retries" );
    like( $caught, qr/^ick/, "caught expected error" );
};

subtest 'conditional gets count' => sub {
    my $count  = 0;
    my $caught = '';
    my @err;
    retry {
        pass("try $count");
        $count++;
        die "ick";
    }
    retry_if { shift() < 3 }
    catch {
        $caught = $_;
    };
    is( $count, 3, "correct number of retries" );
    like( $caught, qr/^ick/, "caught expected error" );
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
