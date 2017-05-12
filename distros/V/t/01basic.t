#!/usr/bin/perl -w
use strict;

# $Id: 01basic.t 575 2004-01-16 13:09:03Z abeltje $

use Test::More tests => 3;

require_ok( 'V' );

ok( $V::VERSION, '$V::VERSION is there' );

SKIP: {
    local *PIPE;
    my $out;
    if ( open PIPE, qq!$^X -Mblib -MV |! ) {
        $out = do { local $/; <PIPE> };
        unless ( close PIPE ) {
            if ( open PIPE, qq!$^X -I. -e 'use V;' |! ) {
                $out = do { local $/; <PIPE> };
                skip "Error in pipe(2): $! [$?]", 1 unless close PIPE;
            } else {
                skip "Could not fork: $!", 1;
            }
            $out or skip "Error in pipe(1): $! [$?]", 1;
        }
    } else {
        skip "Could not fork: $!";
    }

    my( $version ) = $out =~ /^.+?([\d._]+)$/m;

    is( $version, $V::VERSION, "Version ok ($version)" );
}

__END__
