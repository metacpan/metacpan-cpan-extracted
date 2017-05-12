#! /usr/bin/perl -w

#=============================================================================
#
# $Id: 06iter.t,v 0.9 2001/06/30 12:16:04 mneylon Exp $
# $Revision: 0.9 $
# $Author: mneylon $
# $Date: 2001/06/30 12:16:04 $
# $Log: 06iter.t,v $
# Revision 0.9  2001/06/30 12:16:04  mneylon
#
# Initial Release (based on www.perlmonks.org code with some additional
# changes)
#
#
#=============================================================================

use strict;

use Tie::Hash::Stack qw(push_hash reverse_hash);

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

push_hash %test_hash;

$test_hash{ 2 } = "II";
$test_hash{ 4 } = "IV";

push_hash %test_hash;

$test_hash{ 3 } = "trio";
$test_hash{ 5 } = "pente";

( $test_hash{ 1 } eq "one" )   ? ok : notok;
( $test_hash{ 2 } eq "II" )    ? ok : notok;
( $test_hash{ 3 } eq "trio" )  ? ok : notok;
( $test_hash{ 4 } eq "IV" )    ? ok : notok;
( $test_hash{ 5 } eq "pente" ) ? ok : notok;

my @hash_keys = keys %test_hash;
my @exp_keys = (1,2,3,4,5);

@hash_keys = sort @hash_keys; 
@exp_keys = sort @exp_keys;
my $fail = 0;
if ( @hash_keys != @exp_keys ) { $fail = 1; } 
else {
    foreach my $i ( 0..@exp_keys - 1 ) {
	if ( $hash_keys[ $i ] ne $exp_keys[ $i ] ) {
	    $fail = 1;
	    last;
	}
    }
}

!($fail) ? ok : notok;

my @hash_values = values %test_hash;
my @exp_values = ("one","II","trio","IV","pente" );

@hash_values = sort @hash_values; 
@exp_values = sort @exp_values;
$fail = 0;
if ( @hash_values != @exp_values ) { $fail = 1; } 
else {
    foreach my $i ( 0..@exp_values - 1 ) {
	if ( $hash_values[ $i ] ne $exp_values[ $i ] ) {
	    $fail = 1;
	    last;
	}
    }
}

!($fail) ? ok : notok;

my %hash;
while ( my ( $key, $value ) = each %test_hash ) {
    $hash{ $key } = $value;
}

( $hash{ 1 } eq "one" )   ? ok : notok;
( $hash{ 2 } eq "II" )    ? ok : notok;
( $hash{ 3 } eq "trio" )  ? ok : notok;
( $hash{ 4 } eq "IV" )    ? ok : notok;
( $hash{ 5 } eq "pente" ) ? ok : notok;

1;