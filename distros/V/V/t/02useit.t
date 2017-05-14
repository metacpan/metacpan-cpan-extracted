#!/usr/bin/perl -w
use strict;

$|=1;

# $Id: 02useit.t 575 2004-01-16 13:09:03Z abeltje $

use Test::More tests => 6;

package Catch;
sub TIEHANDLE { bless \( my $self ), shift }
sub PRINT  { my $self = shift; $$self .= $_[0] }
sub PRINTF { 
    my $self = shift;
    my $format = shift;
    $$self .= sprintf $format, @_;
}

package main;

my $out;
local *CATCHOUT;
#BEGIN {
    $out = tie *CATCHOUT, 'Catch'; 
    select CATCHOUT;
    require_ok( 'V' );
    $V::NO_EXIT = 1;
#}

V->import( 'V' );
select STDOUT; # Stop gathering output via *CATCHOUT;

ok( $$out, "V->import() produced output" );
like( $$out, qr/^V\n/, "Module is V" );
like( $$out, qr/^\t(.+?)V\.pm: $V::VERSION$/m, "VERSION is $V::VERSION" );
is( $V::NO_EXIT, 1 , "Packagevar \$V::NO_EXIT set" );

is V::get_version( 'V' ), $V::VERSION, "get_version()";
