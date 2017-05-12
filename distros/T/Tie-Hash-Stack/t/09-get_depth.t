#! /usr/bin/perl -w

#=============================================================================
#
# $Id: 09get_depth.t,v 0.9 2001/06/30 12:16:04 mneylon Exp $
# $Revision: 0.9 $
# $Author: mneylon $
# $Date: 2001/06/30 12:16:04 $
# $Log: 09get_depth.t,v $
# Revision 0.9  2001/06/30 12:16:04  mneylon
#
# Initial Release (based on www.perlmonks.org code with some additional
# changes)
#
#
#=============================================================================

use strict;

use Tie::Hash::Stack qw(push_hash pop_hash get_depth);

my $test = 1;
sub ok    { print "ok ",     $test++, "\n"; }
sub notok { print "not ok ", $test++, "\n"; }

print "1..7\n";

my %test_hash;
tie( %test_hash, "Tie::Hash::Stack" );

$test_hash{ 1 } = "one";
$test_hash{ 2 } = "two";
$test_hash{ 3 } = "three";

(get_depth(%test_hash) == 0) ? ok : notok;

push_hash %test_hash;

$test_hash{ 2 } = "II";
$test_hash{ 4 } = "IV";

(get_depth(%test_hash) == 1) ? ok : notok;

push_hash %test_hash;

$test_hash{ 3 } = "trio";
$test_hash{ 5 } = "pente";

(get_depth(%test_hash) == 2) ? ok : notok;

pop_hash %test_hash;

(get_depth(%test_hash) == 1) ? ok : notok;

pop_hash %test_hash;

(get_depth(%test_hash) == 0) ? ok : notok;

pop_hash %test_hash;

(get_depth(%test_hash) == 0) ? ok : notok;

pop_hash %test_hash;

(get_depth(%test_hash) == 0) ? ok : notok;


1;