#! /usr/bin/perl -w

#=============================================================================
#
# $Id: 07merge_hash.t,v 0.9 2001/06/30 12:16:04 mneylon Exp $
# $Revision: 0.9 $
# $Author: mneylon $
# $Date: 2001/06/30 12:16:04 $
# $Log: 07merge_hash.t,v $
# Revision 0.9  2001/06/30 12:16:04  mneylon
#
# Initial Release (based on www.perlmonks.org code with some additional
# changes)
#
#
#=============================================================================

use strict;

use Tie::Hash::Stack qw(push_hash merge_hash);

my $test = 1;
sub ok    { print "ok ",     $test++, "\n"; }
sub notok { print "not ok ", $test++, "\n"; }

print "1..5\n";

my %test_hash;
tie( %test_hash, "Tie::Hash::Stack" );

#
# Default use of hash
#

$test_hash{ 1 } = "one";
$test_hash{ 2 } = "two";
$test_hash{ 3 } = "three";

push_hash %test_hash;

$test_hash{ 2 } = "II";
$test_hash{ 4 } = "IV";

push_hash %test_hash;

$test_hash{ 3 } = "trio";
$test_hash{ 5 } = "pente";

my %merged = merge_hash %test_hash;

( $merged{ 1 } eq "one" )   ? ok : notok;
( $merged{ 2 } eq "II" )    ? ok : notok;
( $merged{ 3 } eq "trio" )  ? ok : notok;
( $merged{ 4 } eq "IV" )    ? ok : notok;
( $merged{ 5 } eq "pente" ) ? ok : notok;

1;