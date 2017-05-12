#============================================================= -*-perl-*-
#
# t/facet.t
#
# Test the XML::Schema::Facet module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: facet.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Facet;
use XML::Schema::Facet::Builtin;
use XML::Schema::Type::Builtin;

#ntests(5);

my ($pkg, $facet, $type, $instance);


#------------------------------------------------------------------------
# base class

$pkg = 'XML::Schema::Facet';

$facet = $pkg->new();
ok( ! $facet );
match( $pkg->error(), "$pkg: value not specified" );

$facet = $pkg->new(10);
ok( $facet );
match( $facet->{ value }, 10 );

$facet = $pkg->new(value => 15);
ok( $facet );
match( $facet->{ value }, 15 );

$facet = $pkg->new(value => 20, annotation => "Hello World", fixed => '??');
ok( $facet );
match( $facet->value(), 20 );
match( $facet->annotation(), "Hello World" );
ok( ! $facet->{ fixed } );

#------------------------------------------------------------------------
# test "Fixed" base class which adds 'fixed' as an optional argument

$pkg = 'XML::Schema::Facet::Fixable';

$facet = $pkg->new(value => 25);
ok( $facet );
match( $facet->value(), 25 );
match( $facet->annotation(), "" );
match( $facet->fixed(), 0 );

$facet = $pkg->new(value => 25, 
		   annotation => "Hello World",
		   fixed => 1);
ok( $facet );
match( $facet->value(), 25 );
match( $facet->annotation(), "Hello World" );
match( $facet->fixed(), 1 );


#------------------------------------------------------------------------
# test name gets set from package name if not otherwise specified

package XML::Schema::Facet::Test1;
use base qw( XML::Schema::Facet );

package main;

$pkg = 'XML::Schema::Facet::Test1';

$facet = $pkg->new(30);
ok( $facet );
match( $facet->value(), 30 );
match( $facet->name(), 'Test1' );

$facet = $pkg->new( value => 40, name => 'MyTestFacet');
ok( $facet, $pkg->error()  );
match( $facet->value(), 40 );
match( $facet->name(), 'MyTestFacet' );


#------------------------------------------------------------------------
# test MANDATORY and OPTIONAL arguments via custom facets

package XML::Schema::Facet::Test2;
use base qw( XML::Schema::Facet );
use vars qw( @MANDATORY @OPTIONAL );

@MANDATORY = qw( foo bar );
@OPTIONAL  = qw( baz qux );

package main;
$pkg = 'XML::Schema::Facet::Test2';
$facet = $pkg->new();
ok( ! $facet );
match( $pkg->error(), "$pkg: value not specified" );

$facet = $pkg->new(10);
ok( ! $facet );
match( $pkg->error(), "$pkg: foo not specified" );

$facet = $pkg->new( value => 101, foo => 'Foo', bar => 'Bar' );
ok( $facet, $pkg->error() );
match( $facet->value, 101 );
match( $facet->{ foo }, 'Foo' );
match( $facet->{ bar }, 'Bar' );
match( $facet->{ baz }, '' );

$facet = $pkg->new( value => 102,
		    foo => 'Foo', bar => 'Bar', 
		    baz => 'Baz', qux => 'Qux' );
ok( $facet );
match( $facet->{ value }, 102 );
match( $facet->{ foo }, 'Foo' );
match( $facet->{ bar }, 'Bar' );
match( $facet->{ baz }, 'Baz' );
match( $facet->{ qux }, 'Qux' );

#------------------------------------------------------------------------
# test MANDATORY and OPTIONAL arguments via built in length facet

$facet = XML::Schema::Facet::length->new( value => 10 );
ok( $facet );
match( $facet->{ value }, 10 );
ok( defined $facet->{ fixed }, 'fixed not defined' );
match( $facet->{ fixed }, '' );

$facet = XML::Schema::Facet::length->new({
    value => 10,
    fixed => 1,
    annotation => 'This is the length facet'
});

ok( $facet );
match( $facet->{ value }, 10 );
match( $facet->{ fixed }, 1 );
match( $facet->{ annotation }, 'This is the length facet' );


#------------------------------------------------------------------------
# length

$facet = XML::Schema::Facet::length->new(value => 22);
match( $facet->name, 'length' );
$instance = { value => 'The cat sat' };
ok( ! $facet->valid($instance) );
match( $facet->error(), 'string has 11 characters (required length: 22)' );
$instance->{ value } .= ' on the mat';
ok( $facet->valid($instance) );

$facet = XML::Schema::Facet::length->new(value => 3);
$instance->{ value } = ['foo', 'bar'];
ok( ! $facet->valid($instance) );
match( $facet->error(), 'list has 2 elements (required length: 3)' );
push(@{ $instance->{ value } }, 'baz');
ok( $facet->valid($instance) );


#------------------------------------------------------------------------
# minLength

$facet = XML::Schema::Facet::minLength->new(value => 22);
match( $facet->name, 'minLength' );

$instance = { value => 'The cat sat' };
ok( ! $facet->valid($instance) );
match( $facet->error(), 'string has 11 characters (required minLength: 22)' );
$instance->{ value } .= ' on the mat';
ok( $facet->valid($instance) );
$instance->{ value } .= ' and shat';
ok( $facet->valid($instance) );

$facet = XML::Schema::Facet::minLength->new(value => 3);
$instance = { value => ['foo', 'bar'] };
ok( ! $facet->valid($instance) );
match( $facet->error(), 'list has 2 elements (required minLength: 3)' );
push(@{ $instance->{ value } }, 'baz');
ok( $facet->valid($instance) );
push(@{ $instance->{ value } }, 'qux');
ok( $facet->valid($instance) );

#------------------------------------------------------------------------
# maxLength

$facet = XML::Schema::Facet::maxLength->new(value => 22);
$instance = { value => 'The cat sat' };
ok( $facet->valid($instance) );
$instance->{ value } .= ' on the mat';
ok( $facet->valid($instance) );
$instance->{ value } .= ' and shat';
ok( ! $facet->valid($instance) );
match( $facet->error(), 'string has 31 characters (required maxLength: 22)' );

$facet = XML::Schema::Facet::maxLength->new(value => 3);
$instance->{ value } = ['foo', 'bar'];
ok( $facet->valid($instance) );
push(@{ $instance->{ value } }, 'baz');
ok( $facet->valid($instance) );
push(@{ $instance->{ value } }, 'qux');
ok( ! $facet->valid($instance) );
match( $facet->error(), 'list has 4 elements (required maxLength: 3)' );

#------------------------------------------------------------------------
# pattern

$facet = XML::Schema::Facet::pattern->new(value => '^\d{3}-\w+$');
$instance->{ value } = 'The cat sat';
ok( ! $facet->valid($instance) );
match( $facet->error(), 'string mismatch (required pattern: ^\d{3}-\w+$)' );
$instance->{ value } = '314-pi';
ok( $facet->valid($instance) );

#------------------------------------------------------------------------
# enumeration

$facet = XML::Schema::Facet::enumeration->new(value => 'hello');
$instance->{ value } = 'goodbye';
ok( ! $facet->valid($instance) );
match( $facet->error(), 
      "string mismatch ('goodbye' not in: 'hello')" );
$instance->{ value } = 'hello';
ok( $facet->valid($instance) );

$facet = XML::Schema::Facet::enumeration->new(value => [ 'hello', 'world' ]);
$instance->{ value } = 'goodbye';
ok( ! $facet->valid($instance) );
match( $facet->error(), 
      "string mismatch ('goodbye' not in: 'hello', 'world')" );
$instance->{ value } = 'hello';
ok( $facet->valid($instance) );
$instance->{ value } = 'world';
ok( $facet->valid($instance), $facet->error() );

#------------------------------------------------------------------------
# whitespace

$pkg = 'XML::Schema::Facet::whiteSpace';
$facet = $pkg->new(value => 'hello');
ok( ! $facet );
match( $pkg->error(), 
      'value must be one of: preserve, replace, collapse' );

$facet = $pkg->new(value => 'preserve');
ok( $facet, $pkg->error() );
$instance->{ value } = " \thello\nworld\r ";
ok( $facet->valid($instance) );
match( $instance->{ value }, " \thello\nworld\r " );


$facet = $pkg->new(value => 'replace');
ok( $facet );
$instance->{ value } = " \thello\nworld\r ";
ok( $facet->valid($instance) );
match( $instance->{ value }, "  hello world  " );

$facet = $pkg->new(value => 'collapse');
ok( $facet );
$instance->{ value } = " \t  hello  \n\n  world \r ";
ok( $facet->valid($instance) );
match( $instance->{ value }, "hello world" );

#------------------------------------------------------------------------
# maxInclusive

$facet = XML::Schema::Facet::maxInclusive->new(value => 42);
$instance->{ value } = 41;
ok( $facet->valid($instance) );
$instance->{ value }++;
ok( $facet->valid($instance) );
$instance->{ value }++;
ok( ! $facet->valid($instance) );
match( $facet->error(), 'value is 43 (required maxInclusive: 42)' );

#------------------------------------------------------------------------
# maxExclusive

$facet = XML::Schema::Facet::maxExclusive->new(value => 42);
$instance->{ value } = 41;
ok( $facet->valid($instance) );
$instance->{ value }++;
ok( ! $facet->valid($instance) );
match( $facet->error(), 'value is 42 (required maxExclusive: 42)' );

#------------------------------------------------------------------------
# minInclusive

$facet = XML::Schema::Facet::minInclusive->new(value => 42);
$instance->{ value } = 43;
ok( $facet->valid($instance) );
$instance->{ value }--;
ok( $facet->valid($instance) );
$instance->{ value }--;
ok( ! $facet->valid($instance) );
match( $facet->error(), 'value is 41 (required minInclusive: 42)' );

#------------------------------------------------------------------------
# minExclusive

$facet = XML::Schema::Facet::minExclusive->new(value => 42);
$instance->{ value } = 43;
ok( $facet->valid($instance) );
$instance->{ value }--;
ok( ! $facet->valid($instance) );
match( $facet->error(), 'value is 42 (required minExclusive: 42)' );

#------------------------------------------------------------------------
# precision

$facet = XML::Schema::Facet::precision->new(value => 4);
$instance = { 
    value => 23.45,
    scale => 2,
    precision => 4,
};
ok( $facet->valid($instance) );
$instance->{ value } = 23.456;
$instance->{ precision } = 5;
ok( ! $facet->valid($instance) );
match( $facet->error(), 'value is 23.456 (required precision: 4)');

package XML::Schema::Test::Type::Foo;
use base qw( XML::Schema::Type::decimal );
use vars qw( @FACETS );

@FACETS = (
    precision => 4,
);

package main;

$pkg = 'XML::Schema::Test::Type::Foo';
$type = $pkg->new();
ok( $type );
ok( $type->instance('123.4') );
ok( ! $type->instance('123.45') );
match( $type->error(), 'value is 123.45 (required precision: 4)' );

#------------------------------------------------------------------------
# scale

$facet = XML::Schema::Facet::scale->new(value => 2);
$instance = { 
    value => 23.45,
    scale => 2,
};
ok( $facet->valid($instance) );
$instance->{ value } = 23.456;
$instance->{ scale } = 3;
ok( ! $facet->valid($instance) );
match( $facet->error(), 'value is 23.456 (required scale: 2)');

package XML::Schema::Test::Type::Bar;
use base qw( XML::Schema::Type::decimal );
use vars qw( @FACETS );

@FACETS = (
    scale => 2,
);

package main;

$pkg = 'XML::Schema::Test::Type::Bar';
$type = $pkg->new();
ok( $type );
ok( $type->instance('123.4') );
ok( $type->instance('123.45') );
ok( ! $type->instance('123.456') );
match( $type->error(), 'value is 123.456 (required scale: 2)' );


#------------------------------------------------------------------------
# encoding
# duration
# period
#
# There are no validation rules associated with these facets.
#



