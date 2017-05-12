#! /usr/bin/perl -w

#=============================================================================
#
# $Id: 01new.t,v 0.9 2001/06/30 12:16:04 mneylon Exp $
# $Revision: 0.9 $
# $Author: mneylon $
# $Date: 2001/06/30 12:16:04 $
# $Log: 01new.t,v $
# Revision 0.9  2001/06/30 12:16:04  mneylon
#
# Initial Release (based on www.perlmonks.org code with some additional
# changes)
#
#
#=============================================================================

use strict;

use Tie::Hash::Stack;

my $test = 1;
sub ok    { print "ok ",     $test++, "\n"; }
sub notok { print "not ok ", $test++, "\n"; }

print "1..3\n";

my ( %test_hash, $val ); 


#
# Default ctor
# 

eval { $val = tie ( %test_hash, "Tie::Hash::Stack" ); };
defined( $val ) ? ok : notok;

#
# Ctor with hashref
# 
undef %test_hash;
$val = undef;

my %set_hash = ( one=>1, two=>2 );
eval { $val = tie ( %test_hash, "Tie::Hash::Stack", \%set_hash ); };
defined( $val ) ? ok : notok;


#
# Ctor with anything else (should fail)
# 
undef %test_hash;
$val = undef;

my $bogus = 4;
eval { $val = tie ( %test_hash, "Tie::Hash::Stack", $bogus ); };
!defined( $val ) ? ok : notok;

1;