#============================================================= -*-perl-*-
#
# t/enum.t
#
# Test simple type enumerations.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: enum.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema;

#ntests(5);

my $schema = XML::Schema->new();

my $string = $schema->simpleType( name => 'myString', 
				  base => 'string' );
$string->constrain( enumeration => [ 'hello', 'goodbye' ] );

my $result = $string->instance('hello');
ok( $result, $string->error() );
