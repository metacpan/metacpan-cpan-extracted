#! /usr/bin/perl -w

#=============================================================================
#
# $Id: 08flatten_hash.t,v 0.9 2001/06/30 12:16:04 mneylon Exp $
# $Revision: 0.9 $
# $Author: mneylon $
# $Date: 2001/06/30 12:16:04 $
# $Log: 08flatten_hash.t,v $
# Revision 0.9  2001/06/30 12:16:04  mneylon
#
# Initial Release (based on www.perlmonks.org code with some additional
# changes)
#
#
#=============================================================================

use strict;

use Tie::Hash::Stack qw(push_hash pop_hash flatten_hash);

my $test = 1;
sub ok    { print "ok ",     $test++, "\n"; }
sub notok { print "not ok ", $test++, "\n"; }

print "1..10\n";

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

#
# Flatten test
#

flatten_hash %test_hash;

( $test_hash{ 1 } eq "one" )   ? ok : notok;
( $test_hash{ 2 } eq "II" )    ? ok : notok;
( $test_hash{ 3 } eq "trio" )  ? ok : notok;
( $test_hash{ 4 } eq "IV" )    ? ok : notok;
( $test_hash{ 5 } eq "pente" ) ? ok : notok;

# 
# If flattened, removing a hash will null it out
#

pop_hash %test_hash;

!( $test_hash{ 1 } )           ? ok : notok;
!( $test_hash{ 2 } )           ? ok : notok;
!( $test_hash{ 3 } )           ? ok : notok;
!( $test_hash{ 4 } )           ? ok : notok;
!( $test_hash{ 5 } )           ? ok : notok;



1;