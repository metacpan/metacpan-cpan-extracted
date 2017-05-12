#!/usr/bin/perl -w
#============================================================= -*-perl-*-
#
# t/complex.t
#
# Test the XML::Schema::Type::Complex module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: complex.t,v 1.2 2001/12/20 13:26:28 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Type;
use XML::Schema;

my $DEBUG = 0;
$XML::Schema::Type::Complex::DEBUG = $DEBUG;

#ntests(86);

my $package = 'XML::Schema::Type::Complex';

my $complex = $package->new( );
assert( $complex, $package->error() );


#------------------------------------------------------------------------
# flag denoting mixed content models
#------------------------------------------------------------------------

ok( ! $complex->mixed() );

$complex = $package->new( empty => 1 );
ok( $complex, $package->error() );

ok( ! $complex->mixed() );

$complex->mixed(0);
ok( ! $complex->mixed() );

$complex->mixed(1);
ok( $complex->mixed() );


#------------------------------------------------------------------------
# attributes
#------------------------------------------------------------------------

ok( ! $complex->attribute() );
match( $complex->error(), 'XML::Schema::Attribute: type not specified' );

ok( ! $complex->attribute( name => 'id' ) );
match( $complex->error(), 'XML::Schema::Attribute: type not specified' );

my $attr = $complex->attribute( name => 'id', type => 'foo' );
ok( $attr, $complex->error() );
match( $attr->name(), 'id' );
ok( ! $attr->type() );
match( $attr->error(), 'no such type: foo' );

my $factory = $XML::Schema::FACTORY;
my $foo = $factory->create( 
    simple => { base => 'string', name => 'fooString', maxLength => 6 } 
);
ok( $foo, $factory->error() );

my $bar = $factory->create( 
    simple => { base => 'string', name => 'barString', maxLength => 12 } 
);
ok( $bar, $factory->error() );

my $schema = XML::Schema->new();
ok( $schema, $XML::Schema::ERROR );
$schema->type( fooType => $foo );
$schema->type( barType => $bar );

$attr = $factory->create( attribute => { 
    name  => 'foo', 
    type  => 'fooType',
    scope => $schema, 
} );
ok( $attr, $factory->error() );
match( $attr->scope(), $schema );

my $cattr = $complex->attribute( $attr );
ok( $cattr, $complex->error() );

match( $attr, $cattr );
match( $cattr->name(), 'foo' );
match( $cattr->typename(), 'fooType' );
match( $cattr->type->name(), 'fooString' );

$cattr = $complex->attribute( 'foo' );
ok( $cattr, $complex->error() );
match( $cattr->name(), 'foo' );
match( $cattr->typename(), 'fooType' );
match( $cattr->type->name(), 'fooString' );

$cattr = $complex->attribute( 'no_such_attr' );
ok( ! $cattr );
match( $complex->error(), 'no such attribute: no_such_attr' );


#------------------------------------------------------------------------
$package = 'XML::Schema::Type::string';
my $string = $package->new( );
ok( $string );
$string->constrain( maxLength => 12 );

$package = 'XML::Schema::Attribute';

$foo = $package->new( name => 'foo', type => $string );
$bar = { type => $string };

$package = 'XML::Schema::Type::Complex';

my $complex2 = $package->new( attributes => { foo => $foo, bar => $bar },
			      empty => 1 );
ok( $complex2, $package->error() );

my $fooref = $complex2->attribute('foo');
match( $fooref, $foo );

my $barref = $complex2->attribute('bar');
ok( $factory->isa( attribute => $barref ) );

ok( $complex2->attribute( name => 'baz', type => $string ), 
    $complex2->error() );
my $bzrref = $complex2->attribute('baz');
ok( $factory->isa( attribute => $barref ) );


#------------------------------------------------------------------------
# simpleType creation
#------------------------------------------------------------------------

my $email = $complex->simpleType( name => 'email', base => 'string' );
ok( $email );

$email->constrain( pattern => '\w+@\w+(\.\w+)+' );

my $instance = $email->instance('foo');
ok( ! $instance );
match( $email->error(), 
       'string mismatch (required pattern: \w+@\w+(\.\w+)+)' );

$instance = $email->instance('foo@bar.com');
ok( $instance );


$email = $complex->simpleType( 'email' );
ok( $email, $complex->error() );

$instance = $email->instance('foo');
ok( ! $instance );
match( $email->error(), 
       'string mismatch (required pattern: \w+@\w+(\.\w+)+)' );

$instance = $email->instance('foo@bar.com');
ok( $instance, $email->error() );


#------------------------------------------------------------------------
# mixed(), empty() and element_only()
#------------------------------------------------------------------------

$package = 'XML::Schema::Type::Complex';

$complex = $package->new( empty => 1 );
ok( ! $complex->mixed() );
ok( $complex->mixed(1) );
ok( $complex->mixed() );

$complex = $package->new( mixed => 0, empty => 1 );
ok( ! $complex->mixed() );
ok( $complex->mixed(1) );
ok( $complex->mixed() );

# NOTE: ignores mixed because no particle/element/model/etc defined
$complex = $package->new( mixed => 1 );
ok( $complex, $package->error() );
ok( $complex->mixed() );
ok( ! $complex->mixed(0) );
ok( ! $complex->mixed() );

ok( $complex->element_only() );
ok( ! $complex->element_only(0) );
ok( ! $complex->element_only() );
ok( $complex->mixed() );
ok( $complex->element_only(1) );
ok( $complex->element_only() );
ok( ! $complex->mixed() );

ok( $complex->empty() );


#------------------------------------------------------------------------
$package = 'XML::Schema::Type::Complex';
my $inner = $package->new( name => 'inner', type => $string );
ok( $inner, $package->error() );

