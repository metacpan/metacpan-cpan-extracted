#!/usr/bin/perl -w
#============================================================= -*-perl-*-
#
# t/attrib.t
#
# Test the XML::Schema::Attribute module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: attribute.t,v 1.2 2001/12/20 13:26:28 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Attribute;
use XML::Schema::Type::Builtin;
$^W = 1;

my $DEBUG = grep(/-d/, @ARGV);
$XML::Schema::Scheduler::DEBUG = $DEBUG;
$XML::Schema::Attribute::DEBUG = $DEBUG;

#ntests(86);
my ($pkg, $type, $attrib);

match( XML::Schema::Attribute::FIXED, 'fixed' );

$pkg  = 'XML::Schema::Type::string';
$type = $pkg->new();
ok( $type, $pkg->error() );


#------------------------------------------------------------------------
# test type/name arguments are mandatory
#------------------------------------------------------------------------

$pkg = 'XML::Schema::Attribute';
$attrib = $pkg->new();
ok( ! $attrib );
match( $pkg->error(), 'XML::Schema::Attribute: type not specified' );

$attrib = $pkg->new( name => 'myAttr');
ok( ! $attrib );
match( $pkg->error(), 'XML::Schema::Attribute: type not specified' );

$attrib = $pkg->new( type => $type);
ok( ! $attrib );
match( $pkg->error(), 'XML::Schema::Attribute: name not specified' );

$attrib = $pkg->new( name => 'myAttr', type => $type);
ok( $attrib );
match( $attrib->name(), 'myAttr' );


#------------------------------------------------------------------------
# test all basic accessors
#------------------------------------------------------------------------

$attrib = $pkg->new({
    name       => 'myAttr', 
    type       => $type,
    namespace  => 'myNamespace',
    scope      => 'global',
});

ok( $attrib, $pkg->error() );
match( $attrib->name(),       'myAttr' );
match( $attrib->type(),       $type );
match( $attrib->namespace(),  'myNamespace' );
match( $attrib->scope(),      'global' );

ok( $attrib->namespace('newNamespace') );
match( $attrib->namespace(), 'newNamespace' );

#------------------------------------------------------------------------
# test value constraints via fixed, default and constraint
#------------------------------------------------------------------------

$attrib = $pkg->new({
    name       => 'foo', 
    type       => 'bar',
    constraint => 'broken',
});

ok( ! $attrib );
match( $pkg->error(), 'constraint value must be an array ref' );

$attrib = $pkg->new({
    name       => 'foo', 
    type       => 'bar',
    constraint => [ broken => 99 ],
});

ok( ! $attrib );
match( $pkg->error(), "constraint type must be 'fixed' or 'default' (not 'broken')" );

$attrib = $pkg->new({
    name       => 'foo', 
    type       => $type,
    constraint => [ fixed => 99 ],
});

ok( $attrib );
match( $attrib->fixed(), 99 );

my ($t, $v) = $attrib->constraint();
match( $t, 'fixed' );
match( $v, 99 );

ok( ! $attrib->default() );
match( $attrib->error(), 'attribute does not define a default value' );

match( $attrib->fixed(), 99 );
match( $attrib->constraint('fixed'), 99 );

ok( $attrib->fixed(98) );
match( $attrib->fixed(), 98 );
match( $attrib->constraint('fixed'), 98 );


ok( $attrib->default(42) );
ok( ! $attrib->fixed() );
match( $attrib->error(), 'attribute does not define a fixed value' );
match( $attrib->default(), 42 );
match( $attrib->constraint('default'), 42 );

ok( $attrib->constraint( fixed => 101 ) );
match( $attrib->fixed(), 101 );
match( $attrib->constraint('fixed'), 101 );
ok( ! $attrib->default() );
match( $attrib->error(), 'attribute does not define a default value' );

$attrib = $pkg->new({
    name  => 'foo', 
    type  => $type,
    fixed => 201,
});

ok( $attrib );
match( $attrib->fixed(), 201 );

($t, $v) = $attrib->constraint();
match( $t, 'fixed' );
match( $v, 201 );

ok( ! $attrib->default() );
match( $attrib->error(), 'attribute does not define a default value' );
match( $attrib->fixed(), 201 );
match( $attrib->constraint('fixed'), 201 );

ok( $attrib->fixed(202) );
match( $attrib->fixed(), 202 );
match( $attrib->constraint('fixed'), 202 );


$attrib = $pkg->new({
    name    => 'foo', 
    type    => $type,
    default => 301,
});

ok( $attrib );
match( $attrib->default(), 301 );

($t, $v) = $attrib->constraint();
match( $t, 'default' );
match( $v, 301 );

ok( ! $attrib->fixed() );
match( $attrib->error(), 'attribute does not define a fixed value' );
match( $attrib->default(), 301 );
match( $attrib->constraint('default'), 301 );

ok( $attrib->default(302) );
match( $attrib->default(), 302 );
ok( $attrib->fixed(303) );
match( $attrib->fixed(), 303 );


#------------------------------------------------------------------------
# test case insensitivity of fixed/default options
#------------------------------------------------------------------------

use XML::Schema::Constants qw( :attribs );

ok( $attrib->constraint( FIXED => 401 ) );
match( $attrib->fixed, 401 );
ok( $attrib->constraint( Fixed => 402 ) );
match( $attrib->fixed, 402 );
ok( $attrib->constraint( FIXED, 402 ) );
match( $attrib->fixed, 402 );
ok( ! $attrib->constraint( fuxed => 402 ) );
match( $attrib->error, "constraint type must be 'fixed' or 'default' (not 'fuxed')" );



#------------------------------------------------------------------------
# test instance() method
#------------------------------------------------------------------------

$pkg  = 'XML::Schema::Type::decimal';
$type = $pkg->new();
ok( $type, $pkg->error() );

$pkg = 'XML::Schema::Attribute';
$attrib = $pkg->new({
    name => 'number', 
    type => $type,
});

$v = $attrib->instance('one two three');
ok( ! $v );
match( $attrib->error(), 'value is not a decimal' );

$v = $attrib->instance('123.45');
ok( $v );

#print STDERR "v: $v->{ value } (scale: $v->{ scale })\n";


$attrib = $pkg->new({
    name => 'number', 
    type => $type,
});

$v = $attrib->instance('');
ok( ! $v );
match( $attrib->error(), 'value is empty' );


$attrib = $pkg->new({
    name => 'number', 
    type => $type,
    default => 3.14,
});

$v = $attrib->instance();
ok( $v, $attrib->error() );
match( $v, '3.14' );

$v = $attrib->instance(2.718);
ok( $v, $attrib->error() );
match( $v, '2.718' );

my $string = XML::Schema::Type::string->new();
ok( $string);

$attrib = $pkg->new({
    name => 'number', 
    type => $type,
    fixed => 3.14,
});

$v = $attrib->instance(3.14);
ok( $v, $attrib->error() );

$v = $attrib->instance(3.15);
ok( ! $v );
match( $attrib->error(), 'value does not match FIXED value of 3.14' );

#------------------------------------------------------------------------

$pkg = 'XML::Schema::Attribute';

$attrib = $pkg->new( name => 'foo', type => 'fooType' );
ok( $attrib, $pkg->error() );
match( $attrib->typename(), 'fooType' );
ok( ! $attrib->type() );
match( $attrib->error(), 'no such type: fooType' );

$pkg = 'XML::Schema::Type::Complex';
my $complex = $pkg->new( name => 'myComplexType', empty => 1 );
ok( $complex, $pkg->error() );
my $st1 = $complex->simpleType( name => 'mySimpleType1', base => 'string' );
ok( $st1, $complex->error() );
my $st2 = $complex->simpleType( name => 'mySimpleType2', base => 'string' );
ok( $st2, $complex->error() );

$pkg = 'XML::Schema::Attribute';
my $attr1 = $pkg->new( name => 'foo', type => 'mySimpleType1', scope => $complex );
ok( $attr1, $pkg->error() );
match( $attr1->typename(), 'mySimpleType1' );
match( $attr1->type(), $st1 );

$pkg = 'XML::Schema::Attribute';
my $attr2 = $pkg->new( name => 'foo', type => $st2, scope => $complex );
ok( $attr2, $pkg->error() );
match( $attr2->typename(), 'mySimpleType2' );
match( $attr2->type(), $st2 );





