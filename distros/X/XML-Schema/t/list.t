#============================================================= -*-perl-*-
#
# t/list.t
#
# Test the list type.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: list.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Type::Builtin;
use XML::Schema::Type::List;
use XML::Schema::Facet::Builtin;

#$XML::Schema::Base::DEBUG = 1;
#$XML::Schema::Type::Simple::DEBUG = 1;

my ($pkg, $list, $items);

my $float = XML::Schema::Type::float->new();
my $time  = XML::Schema::Type::time->new();
my $int   = XML::Schema::Type::int->new();

$pkg = 'XML::Schema::Type::List';

ok( ! $pkg->new() );
match( $pkg->error(), "$pkg: itemType not specified" );

$list = $pkg->new( itemType => $float );
ok( $list );

$items = $list->instance('');
ok( $items );

$items = $list->instance('123.34.45');
ok( !$items );
match( $list->error(), 'list item 0: value is not a valid float' );

$items = $list->instance('123 .34');
ok( !$items );
match( $list->error(), 'list item 1: value is not a valid float' );


#------------------------------------------------------------------------
# derive a list class and specialise by adding a maxLength facet

package XML::Schema::Test::List3;
use base qw( XML::Schema::Type::List );
use vars qw( @FACETS );

@FACETS = (
    maxLength => 3,
);

package main;

$pkg  = 'XML::Schema::Test::List3';

$list = $pkg->new( itemType => $time );
ok( $list );

$items = $list->instance("  \t\n 10:23:24 11:32:06  \t \r \n ");
ok( $items );

$items = $list->instance('10:23:24 11:32:06 11:32:32');
ok( $items );

$items = $list->instance('10:23:24 11:32:06 11:32:32 12:34:54');
ok( ! $items );
match( $list->error(), 'list has 4 elements (required maxLength: 3)' );

$items = $list->instance('10:23:24 11:32 11:32:32 12:34:54');
ok( ! $items );
match( $list->error(), 'list item 1: value is not a valid date' );


#------------------------------------------------------------------------
# constrain the list a little more

$list->constrain( minLength => 2 );

$items = $list->instance('10:23:24');
ok( ! $items );
match( $list->error(), 'list has 1 elements (required minLength: 2)' );

$items = $list->instance('10:23:24 11:32:06');
ok( $items );

$items = $list->instance('10:23:24 11:32:06 11:32:32');
ok( $items );


#------------------------------------------------------------------------
# mess around with the itemType

$pkg  = 'XML::Schema::Type::List';

$list = $pkg->new( itemType => $int );
ok( $list );
ok( $list->instance('1 2 3 45') );

$list->constrain( maxLength => 4 );
ok( $list->instance('1 2 3 45') );
ok( ! $list->instance('1 2 3 4 5') );
match( $list->error(), 'list has 5 elements (required maxLength: 4)' );

# now constrain the underlying type
$int->constrain( maxExclusive => 45 );
ok( $list->instance('1 2 3 44') );
ok( ! $list->instance('1 2 3 45') );
match( $list->error(), 
      'list item 3: value is 45 (required maxExclusive: 45)' );

# test the variety holds
match( $list->variety(), 'list' );
