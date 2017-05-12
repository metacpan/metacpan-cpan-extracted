#============================================================= -*-perl-*-
#
# t/exception.t
#
# Test the XML::Schema::Exception.pm module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: exception.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Exception;

#$XML::Schema::Base::DEBUG = 1;

### NOTE: don't forget to update this value or comment it out ###
#ntests(10);

my ($pkg, $mod);

my ($type, $info) = qw( type_x info_y );

my $e1 = XML::Schema::Exception->new($type, $info);
ok( $e1 );
match( $e1->{ type }, $type );
match( $e1->{ info }, $info );
match( $e1->type(), $type );
match( $e1->info(), $info );
match( $e1->text(), "[$type] $info" );

