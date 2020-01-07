#! perl

use strict;
use warnings;
use Test::More tests => 2;

use lib '.';                    # stupid restriction
require_ok "xt/basic.pl";

$ENV{LC_ALL} = "C";

SKIP: {
    skip "GhostScript (gs) not available", 4
      unless findbin("gs");

    my $gs = `gs --help`;

    if ( $gs =~ /^available devices:/im ) {
	pass("Ghostscript found");
    }
    else {
	BAIL_OUT("Ghostscript found but not executable?. Cannot continue\n");
    }

    my $gv;
    if ( $gs =~ /ghostscript\s+(\d+\.\d+.*?)\s+/i ) {
	$gv = $1;
	diag("Ghostscript version $gv detected.");
    }
    else {
	diag("Cannot establish Ghostscript version. Cross your fingers.");
    }

    foreach my $type ( qw(pngmono pnggray png16 png256 pngalpha jpeggray) ) {
	if ( $gs =~ / $type( |$)/m ) {
	    diag("Found Ghostscript driver for $type");
	}
	else {
	    diag("No Ghostscript driver for $type. You won't be able to use these.");
	}
    }

    foreach my $type ( qw(png16m jpeg) ) {
	if ( $gs =~ / $type( |$)/m ) {
	    diag("Found Ghostscript driver for $type.");
	}
	else {
	    diag("No Ghostscript driver for $type. Some tests fill fail.");
	}
    }

    my $needpbm = 0;
    foreach my $type ( qw(gif gifmono) ) {
	if ( $gs =~ / $type( |$)/m ) {
	    diag("Found Ghostscript driver for $type.");
	}
	else {
	    diag("No Ghostscript driver for $type. PBM fallback required.");
	    $needpbm = 1;
	}
    }

    if ( $needpbm ) {
	my $pbm;
	if ( findbin("ppmtogif") ) {
	    ( $pbm ) = `ppmtogif --version 2>&1` =~ /pbm version: (.*)/i;
	    if ( $pbm ) {
		diag("PBM version $pbm detected.");
	    }
	}
	unless ( $pbm ) {
	    diag("No PBM found. You won't be able to generate GIF images.");
	}
    }
}
