#!/usr/bin/perl -w
#============================================================= -*-perl-*-
#
# t/constants.t
#
# Test the XML::Schema::Constants module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: constants.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Constants qw( :all );
$^W = 1;

#ntests(9);


#------------------------------------------------------------------------
# these are all rather stupid tests, but they do at least
# validate that the module was loaded correctly and defines
# the right constants

match( FIXED,      'fixed' );
match( FIXED,      &FIXED );
match( FIXED,      &XML::Schema::Constants::FIXED );
match( FIXED,       XML::Schema::Constants::FIXED );

match( DEFAULT,    'default'    );
match( OPTIONAL,   'optional'   );
match( REQUIRED,   'required'   );
match( PROHIBITED, 'prohibited' );
match( UNBOUNDED,  'unbounded'  );


#------------------------------------------------------------------------
# test import of constants

package Blam;

use XML::Schema::Constants qw( :attribs );

*match = \&main::match;
*ok    = \&main::ok;

match( FIXED,    'fixed' );
match( OPTIONAL, 'optional' );
eval { &UNBOUNDED };
if ($@) {
    ok( $@ =~ /^Undefined subroutine &Blam::UNBOUNDED called/ );
}
else {
    ok( 0, 'UNBOUNDED should not be defined' );
}
	
