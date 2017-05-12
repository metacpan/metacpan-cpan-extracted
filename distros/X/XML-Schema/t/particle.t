#============================================================= -*-perl-*-
#
# t/particle.t
#
# Test the XML::Schema::Particle module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: particle.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Particle;
use XML::Schema::Particle::Sequence;
use XML::Schema::Element;
use XML::Schema::Type;

my $DEBUG = grep '-d', @ARGV;
$XML::Schema::Particle::DEBUG = $DEBUG;
$XML::Schema::Particle::Sequence::DEBUG = $DEBUG;
$XML::Schema::Particle::Element::DEBUG = $DEBUG;

#ntests(50);


my $name = 'animal';

my $string = XML::Schema::Type::string->new( maxLength => 12 );
ok( $string, $XML::Schema::Type::string::ERROR );

my $element = XML::Schema::Element->new( name => 'animal', type => $string );
ok( $element, $XML::Schema::Element::ERROR );

my $package = 'XML::Schema::Particle';
my $particle = $package->new();

ok( ! $particle );
match( $package->error(), "particle expects one of: element, sequence, choice, model" );


$particle = $package->new( element => $element );
ok( $particle, $package->error() );
match( $particle->element(), $element );
match( $particle->minOccurs(), 1 );
match( $particle->maxOccurs(), 1 );
match( $particle->min(), 1 );
match( $particle->max(), 1 );

use XML::Schema::Particle::Element;
$package = 'XML::Schema::Particle::Element';

$particle = $package->new( element   => $element, 
			   minOccurs => 0, 
			   maxOccurs => 5 );
ok( $particle, $package->error() );
match( $particle->element(), $element );
match( $particle->minOccurs(), 0 );
match( $particle->maxOccurs(), 5 );
match( $particle->min(), 0 );
match( $particle->max(), 5 );

$particle = $package->new( element => $element, 
			   min     => 5, 
			   max     => 10 );
ok( $particle, $package->error() );
match( $particle->element(), $element );
match( $particle->minOccurs(), 5 );
match( $particle->maxOccurs(), 10 );
match( $particle->min(), 5 );
match( $particle->max(), 10 );

$particle = $package->new( element => $element, 
			   min     => 10, 
			   max     => 5 );
ok( ! $particle );
match( $package->error(), "maxOccurs (5) is less than minOccurs (10)" );


#------------------------------------------------------------------------
$particle = $package->new( element => $element, 
			   min     => 1, 
			   max     => 2 );
ok( $particle, $package->error() );
ok( $particle->start() );
my $e = $particle->element( $name );
ok( $e );
$e = $particle->element( $name );
ok( $e );

# should fail this time - had 2 already
$e = $particle->element( $name );
ok( ! $e );
match( $particle->error(), 'maximum of 2 <animal> elements exceeded' );

# check it fails again
$e = $particle->element( $name );
ok( ! $e );
match( $particle->error(), 'maximum of 2 <animal> elements exceeded' );

# reset and repeat the whole thing
$particle->start();
$e = $particle->element( $name );
ok( $e );
$e = $particle->element( $name );
ok( $e );
match( $particle->occurs(), 2);
$e = $particle->element( $name );
ok( ! $e );
match( $particle->error(), 'maximum of 2 <animal> elements exceeded' );
match( $particle->occurs(), 2);

# now try a min failure
$particle->start();
$e = $particle->element( 'nextelement' );
ok( ! $e );
match( $particle->error(), 'unexpected <nextelement> found (min. 1 <animal> element required)' );

$particle->start();
ok( ! $particle->end() );
match( $particle->error(), 'minimum of 1 <animal> element expected' );

$particle->min(2);
$particle->start();
ok( ! $particle->end() );
match( $particle->error(), 'minimum of 2 <animal> elements expected' );
