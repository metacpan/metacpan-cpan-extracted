#============================================================= -*-perl-*-
#
# t/element.t
#
# Test the XML::Schema::Element module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: element.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Element;
#use XML::Schema::Parser;
use XML::Schema;
$^W = 1;

my $DEBUG = 0;
$XML::Schema::Scheduler::DEBUG = $DEBUG;
$XML::Schema::Element::DEBUG = $DEBUG;

my ($pkg, $type, $element);

$pkg  = 'XML::Schema::Type::string';
$type = $pkg->new();
ok( $type );

$pkg  = 'XML::Schema::Element';
$element = $pkg->new( name => 'myelement', type => $type );
ok( $element, $pkg->error() );
match( $element->name(), 'myelement' );
ok( $element->name('newname') );
match( $element->name(), 'newname' );


#------------------------------------------------------------------------
my $strpkg = 'XML::Schema::Type::string';
my $string = $strpkg->new();
ok( $string, $strpkg->error() );

my $complexpkg = 'XML::Schema::Type::Complex';
my $innertype = $complexpkg->new( name => 'innerType', type => $string );
ok( $innertype, $complexpkg->error() );

my $elempkg = 'XML::Schema::Element';
my $inner = $elempkg->new( name => 'inner', type => $innertype );
ok( $inner, $elempkg->error() );

my $outertype = $complexpkg->new( name => 'outerType', element => $inner );
ok( $outertype, $complexpkg->error() );
match( $outertype->content->particle->min(), 1 );
match( $outertype->content->particle->max(), 1 );
match( $outertype->content->particle->element->name(), 'inner' );

$outertype = $complexpkg->new({
    name => 'outerType', 
    content => {
	element   => $inner,
	maxOccurs => 3,
	minOccurs => 2,
    },
});
ok( $outertype, $complexpkg->error() );
match( $outertype->content->particle->min(), 2 );
match( $outertype->content->particle->max(), 3 );
match( $outertype->content->particle->element->name(), 'inner' );

$outertype = $complexpkg->new({
    name => 'outerType', 
    element   => $inner,
    max => 3,
    min => 2,
});
ok( $outertype, $complexpkg->error() );
match( $outertype->content->particle->min(), 2 );
match( $outertype->content->particle->max(), 3 );
match( $outertype->content->particle->element->name(), 'inner' );
#print $outertype->content->particle->_dump();

