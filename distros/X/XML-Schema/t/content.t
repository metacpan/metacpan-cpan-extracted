#!/usr/bin/perl -w                                         # -*- perl -*-
#============================================================= -*-perl-*-
#
# t/content.t
#
# Test the XML::Schema::Content module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: content.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Content;
use XML::Schema::Type::Complex;

my $DEBUG = 0;
$XML::Schema::Content::DEBUG = $DEBUG;
$XML::Schema::Type::Complex::DEBUG = $DEBUG;

#ntests(65);

my $name = 'animal';

my $package = 'XML::Schema::Content';

# test empty
my $content = $package->new( empty => 1 );
ok( $content, $package->error() );
ok( $content->empty() );
ok( ! $content->mixed() );
ok( ! $content->type() );
ok( ! $content->particle() );
ok( ! $content->model() );

#========================================================================
# NOTE: the following tests are temporarily commented out because I've 
# disabled the 'type' facility for content until I can work out how to
# implement the parser handler for it (e.g. element with attributes but
# simple content)
#========================================================================

# test with type
# my $type = 'MyType';
# $content = $package->new( type => $type );
# ok( $content, $package->error() );
# ok( ! $content->empty() );
# ok( ! $content->mixed() );
# match( $content->type(), $type );
# ok( ! $content->particle() );
# ok( $content->model(), $type );
# 
# $content = $package->new( type => $type, mixed => 1 );
# ok( $content, $package->error() );
# ok( ! $content->empty() );
# ok( $content->mixed() );
# match( $content->type(), $type );
# ok( ! $content->particle() );
# ok( $content->model(), $type );

# test with particle
my $particle = 'MyParticle';
$content = $package->new( particle => $particle );
ok( $content, $package->error() );
ok( ! $content->empty() );
ok( ! $content->mixed() );
ok( ! $content->type() );
match( $content->particle(), $particle );
ok( $content->model(), $particle );

# test mixed with particle
$content = $package->new( particle => $particle, mixed => 1 );
ok( $content, $package->error() );
ok( ! $content->empty() );
ok(   $content->mixed() );
ok( ! $content->type() );
match( $content->particle(), $particle );
ok( $content->model(), $particle );


#------------------------------------------------------------------------
# test creation of internal content model
#------------------------------------------------------------------------

$package = 'XML::Schema::Type::Complex';

# test empty
my $complex = $package->new( empty => 1 );
ok( $complex, $package->error() );

$content = $complex->content();
ok( $content, $complex->error() );
ok( $content->empty() );
ok( ! $content->mixed() );
ok( ! $content->type() );
ok( ! $content->particle() );
ok( ! $content->model() );

#========================================================================
# SEE NOTE ABOVE
#========================================================================
# test with type
# $type = 'MyType';
# $complex = $package->new( type => $type);
# ok( $complex, $package->error() );
# 
# $content = $complex->content();
# ok( $content, $package->error() );
# 
# ok( ! $content->empty() );
# ok( ! $content->mixed() );
# match( $content->type(), $type );
# ok( ! $content->particle() );
# ok( $content->model(), $type );
# 
# # make sure mixed is ignored
# $complex = $package->new( type => $type, mixed => 1 );
# ok( $complex, $package->error() );
# 
# $content = $complex->content();
# ok( $content, $package->error() );
# 
# ok( ! $content->empty() );
# ok( $content->mixed() );
# match( $content->type(), $type );
# ok( ! $content->particle() );
# ok( $content->model(), $type );


# test with particle
$particle = 'MyParticle';
$complex = $package->new( particle => $particle );
ok( $complex, $package->error() );

$content = $complex->content();
ok( $content, $package->error() );

ok( ! $content->empty() );
ok( ! $content->mixed() );
ok( ! $content->type() );
match( $content->particle(), $particle );
ok( $content->model(), $particle );


# test mixed with particle
$complex = $package->new( particle => $particle, mixed => 1 );
ok( $complex, $package->error() );

$content = $complex->content();
ok( $content, $package->error() );

ok( ! $content->empty() );
ok(   $content->mixed() );
ok( ! $content->type() );
match( $content->particle(), $particle );
ok( $content->model(), $particle );

#========================================================================

__END__


# test with a model
$complex = $package->new( element => 'myElement' );
ok( $complex, $package->error() );

$content = $complex->content();
ok( $content, $package->error() );

ok( ! $content->empty() );
ok( ! $content->mixed() );
ok( ! $content->type() );
match( ${ $content->particle()->model() }, $model );
ok( $content->model(), $model );


# test with element
$package = 'XML::Schema::Type::string';

my $string = $package->new();
ok( $string, $package->error() );

my $factory = $XML::Schema::FACTORY;

my $elemname = 'MyElement';
my $element = $factory->element( name => $elemname, type => $string );
ok( $element, $factory->error() );

$complex = $factory->complex( 
    mixed => 1,
    content => $element 
);
ok( $complex, $factory->error() );

$content = $complex->content();
ok( $content, $complex->error() );

ok( ! $content->empty() );
ok(   $content->mixed() );
ok( ! $content->type() );
match( $content->particle->element->name, $elemname );
ok( $content->model(), $model );


# test with a particle
my $elemname = 'MyElement';
my $particle = $factory->particle( element => $element );
ok( $particle, $factory->error() );

$complex = $factory->complex( 
    mixed => 1,
    content => $particle 
);
ok( $complex, $factory->error() );

$content = $complex->content();
ok( $content, $complex->error() );

ok( ! $content->empty() );
ok(   $content->mixed() );
ok( ! $content->type() );
match( $content->particle->element->name, $elemname );
ok( $content->model(), $model );


