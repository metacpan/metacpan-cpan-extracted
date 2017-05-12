#!/usr/bin/perl -w                                         # -*- perl -*-
#============================================================= -*-perl-*-
#
# t/sequence.t
#
# Test the XML::Schema::Particle::Sequence module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: sequence.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Element;
use XML::Schema::Content;
use XML::Schema::Particle::Sequence;
#use XML::Schema::Parser;
$^W = 1;

my $DEBUG = grep '-d', @ARGV;
$DEBUG = 4 if $DEBUG;
$XML::Schema::Element::DEBUG = $DEBUG;
$XML::Schema::Content::DEBUG = $DEBUG;
$XML::Schema::Particle::Sequence::DEBUG = $DEBUG;

my $factory = $XML::Schema::FACTORY;

my $foo = $factory->element( name => 'foo', type => 'string' );
ok( $foo, $factory->error() );
match( $foo->name(), 'foo' );
match( $foo->typename(), 'string' );
ok( $foo->type(), $foo->error() );
match( $foo->type->name(), 'string' );

my $bar = $factory->element( name => 'bar', type => 'time' );
ok( $bar, $factory->error() );
match( $bar->name(), 'bar' );
match( $bar->typename(), 'time' );
ok( $bar->type(), $bar->error() );
match( $bar->type->name(), 'time' );


my $complex = $factory->complex({
    name     => 'foobarType',
    sequence => [{
	element => $foo,
	min     => 1,
	max     => 3,
    },{
	min     => 0,
	max     => 1,
    }],
});

ok( ! $complex );
match( $factory->error(), 'error in sequence item 1: particle expects one of: element, sequence, choice, model' );

$complex = $factory->complex({
    name     => 'foobarType',
    sequence => [{
	element => $foo,
	min     => 1,
	max     => 3,
    },{
	element => $bar,
	min     => 0,
	max     => 1,
    }],
});

ok( $complex, $factory->error() );

$complex = $factory->complex( name => 'foobarType' );
#$XML::Schema::Type::Complex::DEBUG = 1;
ok( $complex->sequence( min => 3, max => 4, 
			{ element => $foo, max => 99  }, 
			{ element => $bar } ),
    $complex->error() );

match( $complex->content->mixed, 0 );
match( $complex->content->model->type(), 'sequence' );
match( $complex->content->model->min(), '3' );
match( $complex->content->model->max(), '4' );
match( $complex->content->model->particles->[0]->max(), '99' );

