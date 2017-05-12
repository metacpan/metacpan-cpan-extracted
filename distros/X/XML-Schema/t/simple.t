#============================================================= -*-perl-*-
#
# t/simple.t
#
# Test the XML::Schema::Type::Simple module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: simple.t,v 1.2 2001/12/20 13:26:28 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Type::Simple;
$^W = 1;

my $DEBUG = grep(/-d/, @ARGV);
$XML::Schema::Scheduler::DEBUG = $DEBUG;
$XML::Schema::Type::Simple::DEBUG = $DEBUG;

ntests(48);
my ($pkg, $type, $item);


#------------------------------------------------------------------------
# simple type module

package XML::Schema::Type::Test::Foo;
use base qw( XML::Schema::Type::Simple );

package main;

$pkg  = 'XML::Schema::Type::Test::Foo';
$type = $pkg->new();
ok( $type, $pkg->error() );
match( $type->name(), 'Foo' );
match( $type->variety(), 'atomic' );

$item = $type->instance('10');
ok( $item );
match( $item->{ value }, 10 );

#------------------------------------------------------------------------
# test $NAME can be set

package XML::Schema::Type::Test::Bar;
use base qw( XML::Schema::Type::Simple );

package main;

$pkg  = 'XML::Schema::Type::Test::Bar';
$type = $pkg->new();
ok( $type, $pkg->error() );
match( $type->name(), 'Bar' );

$item = $type->instance('10');
ok( $item );
match( $item->{ value }, 10 );


#------------------------------------------------------------------------
# test annotation

$pkg  = 'XML::Schema::Type::Test::Bar';
$type = $pkg->new();
ok( $type, $pkg->error() );
match( $type->name(), 'Bar' );
ok( ! $type->annotation() );

my $a = 'This is a test';
$type->annotation($a);
match( $type->annotation(), $a );

$type = $pkg->new(annotation => $a);
ok( $type, $pkg->error() );
match( $type->name(), 'Bar' );
match( $type->annotation(), $a );


#------------------------------------------------------------------------
# tests @FACETS work with simple value and hash of values

package XML::Schema::Type::Test::Baz;
use base qw( XML::Schema::Type::Simple );
use vars qw( @FACETS );

@FACETS = (
    maxLength => 20,
    minLength => { value => 10 },
);

package main;

$pkg  = 'XML::Schema::Type::Test::Baz';
$type = $pkg->new();
ok( $type, $pkg->error() );
match( $type->name(), 'Baz' );

$item = $type->instance('abc');
ok( ! $item );
match( $type->error(), 
      'string has 3 characters (required minLength: 10)' );

$item = $type->instance('abcdefghijklmnop');
ok( $item );
match( $type->error(), '' );

$item = $type->instance('abcdefghijklmnopqrstuvwxyz');
ok( ! $item );
match( $type->error(), 
       'string has 26 characters (required maxLength: 20)' );


#------------------------------------------------------------------------
# test @FACETS works with pre-instantiated facet objects

package XML::Schema::Type::Test::Qux;
use base qw( XML::Schema::Type::Simple );
use vars qw( @FACETS );

@FACETS = (
    XML::Schema::Facet::maxLength->new(value => 20)
	|| die(XML::Schema::Facet::maxLength->error()),
    XML::Schema::Facet::minLength->new(10) 
	|| die(XML::Schema::Facet::minLength->error()),
);

package main;

$pkg  = 'XML::Schema::Type::Test::Qux';
$type = $pkg->new();
ok( $type, $pkg->error() );
match( $type->name(), 'Qux' );

$item = $type->instance('abc');
ok( ! $item );
match( $type->error(), 
      'string has 3 characters (required minLength: 10)' );

$item = $type->instance('abcdefghijklmnop');
ok( $item );
match( $type->error(), '' );

$item = $type->instance('abcdefghijklmnopqrstuvwxyz');
ok( ! $item );
match( $type->error(), 
       'string has 26 characters (required maxLength: 20)' );



#------------------------------------------------------------------------
# test that types can be subclassed and all @FACETS are correctly
# inherited

package XML::Schema::Type::Test::Min;
use base qw( XML::Schema::Type::Simple );
use vars qw( @FACETS );

@FACETS = (
    minInclusive => 10,
);

package XML::Schema::Type::Test::Max;
use base qw( XML::Schema::Type::Simple );
use vars qw( @FACETS );

@FACETS = (
    maxInclusive => 20,
);

package XML::Schema::Type::Test::MinMax;
use base qw( XML::Schema::Type::Test::Min
	     XML::Schema::Type::Test::Max );

package main;

$pkg  = 'XML::Schema::Type::Test::MinMax';
$type = $pkg->new();
ok( $type, $pkg->error() );
match( $type->name(), 'MinMax' );

$item = $type->instance(5);
ok( ! $item );
match( $type->error(), 'value is 5 (required minInclusive: 10)' );

$item = $type->instance(10);
ok( $item );
$item = $type->instance(15);
ok( $item );
$item = $type->instance(20);
ok( $item );

$item = $type->instance(25);
ok( ! $item );
match( $type->error(), 'value is 25 (required maxInclusive: 20)' );


#------------------------------------------------------------------------
# test that subclasses can be insantiated by calling the base class
# with a 'base' argument

#$XML::Schema::Type::Simple::DEBUG = 1;
$pkg = 'XML::Schema::Type::Simple';

my $atype = $pkg->new( );
ok( $atype, $pkg->error() );
match( $atype->type(), 'anyType' );

my $bstring = $pkg->new( base => 'string'  );
ok( $bstring, $pkg->error() );
match( $bstring->type(), 'string' );

my $cdate = $pkg->new( base => 'date'  );
ok( $cdate, $pkg->error() );
match( $cdate->type(), 'date' );


#------------------------------------------------------------------------
# test visit_facets()

package My::Visitor;
sub new {
    my $class = shift;
    bless { }, $class;
}
sub visit_facet {
    my ($self, $facet) = @_;
    print STDERR "visiting facet: $facet\n" if $DEBUG;
}

package main;
    
$XML::Schema::Type::Simple::DEBUG = 1;
$pkg  = 'XML::Schema::Type::Test::Min';
$type = $pkg->new();
ok( $type, $pkg->error() );

$type->constrain( maxInclusive => 30 );

my $visitor = My::Visitor->new();
$type->visit_facets($visitor);
