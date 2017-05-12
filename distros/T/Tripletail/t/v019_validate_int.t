#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/v019_validate_int.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: v019_validate_int.t 4033 2006-10-10 03:29:52Z hio $
# -----------------------------------------------------------------------------
use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;
use File::Spec;
use Tripletail File::Spec->devnull;

&test_001;

sub test_001
{
	my $validator = $TL->newValidator();
	$validator->addFilter({ival => "Integer"});
	
	my $err = $validator->check( $TL->newForm( ival => 0 ) );
	is_deeply($err, undef, "0 is valid integer");
	
	$err = $validator->check( $TL->newForm() );
	is_deeply($err, {ival=>"Integer"}, "no item is not valid integer (1)");
	
	$err = $validator->check( $TL->newForm( ival => [] ) );
	is_deeply($err, {ival=>"Integer"}, "no item is not valid integer (2)");
	
	$err = $validator->check( $TL->newForm( ival => '' ) );
	is_deeply($err, {ival=>"Integer"}, "empty string is not valid integer");
	
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
