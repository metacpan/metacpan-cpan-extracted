#!/usr/bin/perl -w
#============================================================= -*-perl-*-
#
# t/scope.t
#
# Test the XML::Schema::Scope module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: scope.t,v 1.2 2001/12/20 13:26:28 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema;
use XML::Schema::Test;
use XML::Schema::Scope;

my $DEBUG = 0;
$XML::Schema::Scope::DEBUG = $DEBUG;

#ntests(54);

my $package = 'XML::Schema::Scope';

my $scope = $package->new();
ok( $scope, $package->error() );


#------------------------------------------------------------------------
# simpleType creation
#------------------------------------------------------------------------

my $email = $scope->simpleType( name => 'email', base => 'string' );
ok( $email );

$email->constrain( pattern => '\w+@\w+(\.\w+)+' );

my $instance = $email->instance('foo');
ok( ! $instance );
match( $email->error(), 
       'string mismatch (required pattern: \w+@\w+(\.\w+)+)' );

$instance = $email->instance('foo@bar.com');
ok( $instance );


$email = $scope->simpleType( 'email' );
ok( $email, $scope->error() );

$instance = $email->instance('foo');
ok( ! $instance );
match( $email->error(), 
       'string mismatch (required pattern: \w+@\w+(\.\w+)+)' );

$instance = $email->instance('foo@bar.com');
ok( $instance, $email->error() );


#------------------------------------------------------------------------
# test builtin types
#------------------------------------------------------------------------

my $string = $scope->simpleType( name => 'foo', base => 'broken' );
ok( ! $string );
match( $scope->error(), 'invalid base type: broken' );

$XML::Schema::Scope::DEBUG = 1;
$string = $scope->simpleType('string');
ok( $string, $scope->error() );
match( $string->name(), "string" );
match( ref $string, 'XML::Schema::Type::string' );

my $date = $scope->simpleType('date');
ok( $date, $scope->error() );
match( $date->name(), "date" );
match( ref $date, 'XML::Schema::Type::date' );



#------------------------------------------------------------------------
# test attribute groups
#------------------------------------------------------------------------

$scope = $package->new();
assert( $scope );

my $groups = $scope->attribute_group();
ok( $groups, $scope->error() );
match( ref $groups, 'HASH' );
match( scalar keys %$groups, 0 );

ok( ! $scope->attribute_group('foo') );
match( $scope->error(), 'no such attribute group: foo' );

my $group = $scope->attribute_group({
    attributes => {
	foo => 'string',
	bar => 'integer',
    },
});
ok( ! $group );
match( $scope->error(), 'XML::Schema::Attribute::Group: name not specified' );

$group = $scope->attribute_group({
    name => 'myGroup',
    attributes => {
	foo => 'string',
	bar => 'integer',
    },
});
assert( $group, $scope->error() );

my $get_group = $scope->attribute_group('myGroup');
ok( $get_group, $scope->error() );
match( $group, $get_group );

my $in = {
    foo => 'hello world',
    bar => 99,
};

my $out = $group->validate($in);
assert( $out, $group->error() );
match( $out->{ foo }, 'hello world' );
match( $out->{ bar }, '99' );
