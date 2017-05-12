#============================================================= -*-perl-*-
#
# t/instance.t
#
# Test the XML::Schema::Instance module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: instance.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema;
use XML::Schema::Instance;
use XML::Schema::Test;

my $DEBUG = 0;
$XML::Schema::DEBUG = $DEBUG;
$XML::Schema::Instance::DEBUG = $DEBUG;

my $schema = XML::Schema->new();
ok( $schema, $XML::Schema::ERROR );

my $instance = XML::Schema::Instance->new( schema => $schema );
ok( $instance, $XML::Schema::Instance::ERROR );

$instance = $schema->instance();
ok( $instance, $schema->error() );

ok( $instance->id(foo => 'the foo node') );
ok( ! $instance->idref('bar') );
match( $instance->error(), "no such id: bar" );
match( $instance->idref('foo'), 'the foo node' );

ok( ! $instance->id('foo') );
match( $instance->error(), "no value defined, did you mean to call idref()?" );
