#!/usr/bin/perl -w                                         # -*- perl -*-
#============================================================= -*-perl-*-
#
# t/choice.t
#
# Test the XML::Schema::Particle::Choice module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: choice.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Element;
use XML::Schema::Content;
use XML::Schema::Particle::Choice;
#use XML::Schema::Parser;
$^W = 1;

#ntests(14);

my $DEBUG = grep '-d', @ARGV;
$DEBUG = 4 if $DEBUG;
$XML::Schema::Element::DEBUG = $DEBUG;
$XML::Schema::Content::DEBUG = $DEBUG;
$XML::Schema::Particle::Choice::DEBUG = $DEBUG;

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
    choice => [{
	element => $foo,
	min     => 1,
	max     => 3,
    },{
	min     => 0,
	max     => 1,
    }],
});

ok( ! $complex );
match( $factory->error(), 'error in choice item 1: particle expects one of: element, sequence, choice, model' );

$complex = $factory->complex({
    name   => 'foobarType',
    choice => [{
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
ok( $complex->choice( min => 3, max => 4, 
		    { element => $foo, max => 99  }, 
		    { element => $bar } ),
    $complex->error() );

match( $complex->content->mixed, 0 );
match( $complex->content->model->type(), 'choice' );
match( $complex->content->model->min(), '3' );
match( $complex->content->model->max(), '4' );
match( $complex->content->model->particles->[0]->max(), '99' );

my $choice = $complex->content->model;

#$complex->{ _DEBUG } = 1;
#$complex->TRACE("choice: ", $choice);

#$XML::Schema::Particle::Choice::DEBUG = 5;
#$XML::Schema::Particle::Sequence::DEBUG = 5;
#$XML::Schema::Particle::Element::DEBUG = 5;
#$choice->{ _DEBUG } = 5;

ok( $choice->start(), $choice->error() );
my $e = $choice->element('bar');
ok( $e, $choice->error() );
#print "e: $e\n";
#ok( $choice->match('bar'), $choice->error() );






