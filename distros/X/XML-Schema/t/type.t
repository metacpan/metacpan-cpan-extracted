#============================================================= -*-perl-*-
#
# t/type.t
#
# Test the XML::Schema::Type module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: type.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Type;
$^W = 1;

#$XML::Schema::Type::DEBUG = 1;

my ($pkg, $type, $item);


#------------------------------------------------------------------------
# simple type module destined for failure

package XML::Schema::Type::Test::Foo;
use base qw( XML::Schema::Type );

package main;

$pkg  = 'XML::Schema::Type::Test::Foo';
$type = $pkg->new();


#------------------------------------------------------------------------
# simple type module destined for success

package XML::Schema::Type::Test::Bar;
use base qw( XML::Schema::Type );

sub init {
    my ($self, $config) = @_;

    $config->{ base } ||= 'random base class';
    $self->SUPER::init($config);
}

package main;

$pkg  = 'XML::Schema::Type::Test::Bar';
$type = $pkg->new();
ok( $type, $pkg->error() );
match( $type->base(), 'random base class' );

$type = $pkg->new(name => 'MyName', namespace => 'http://test.org/');
ok( $type, $pkg->error() );
match( $type->name(), 'MyName' );
match( $type->namespace(), 'http://test.org/' );

