#! /usr/bin/perl -w

#=============================================================================
#
# $Id: 04unshift_hash.t,v 0.9 2001/06/30 12:16:04 mneylon Exp $
# $Revision: 0.9 $
# $Author: mneylon $
# $Date: 2001/06/30 12:16:04 $
# $Log: 04unshift_hash.t,v $
# Revision 0.9  2001/06/30 12:16:04  mneylon
#
# Initial Release (based on www.perlmonks.org code with some additional
# changes)
#
#
#=============================================================================

use strict;

use Tie::Hash::Stack qw(unshift_hash);

my $test = 1;
sub ok    { print "ok ",     $test++, "\n"; }
sub notok { print "not ok ", $test++, "\n"; }

print "1..12\n";

my %test_hash;
tie( %test_hash, "Tie::Hash::Stack" );

#
# Default use of hash
#

$test_hash{ 1 } = "one";
$test_hash{ 2 } = "two";
$test_hash{ 3 } = "three";

( $test_hash{ 1 } eq "one" )   ? ok : notok;
( $test_hash{ 2 } eq "two" )   ? ok : notok;
( $test_hash{ 3 } eq "three" ) ? ok : notok;

#
# New hash (empty by default)
#

unshift_hash %test_hash;

$test_hash{ 2 } = "II";
$test_hash{ 4 } = "IV";

( $test_hash{ 1 } eq "one" )   ? ok : notok;
( $test_hash{ 2 } eq "II" )   ? ok : notok;
( $test_hash{ 3 } eq "three" ) ? ok : notok;
( $test_hash{ 4 } eq "IV" )    ? ok : notok;

#
# New specified hash
#

my %new_hash = ( 3=>"trio", 5=>"pente" );
unshift_hash %test_hash,  %new_hash;

( $test_hash{ 1 } eq "one" )   ? ok : notok;
( $test_hash{ 2 } eq "II" )   ? ok : notok;
( $test_hash{ 3 } eq "three" ) ? ok : notok;
( $test_hash{ 4 } eq "IV" )    ? ok : notok;
( $test_hash{ 5 } eq "pente" ) ? ok : notok;

1;