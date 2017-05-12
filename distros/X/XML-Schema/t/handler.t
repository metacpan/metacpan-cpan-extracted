#============================================================= -*-perl-*-
#
# t/handler.t
#
# Test the XML::Schema::Handler::* modules.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: handler.t,v 1.2 2001/12/20 13:26:28 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Handler::Simple;
use XML::Schema::Handler::Complex;
use XML::Schema::Type;
use XML::Schema::Instance;
use XML::Schema::Content;

ntests(52);

my $DEBUG = grep '-d', @ARGV;
$XML::Schema::Handler::DEBUG = $DEBUG ? 4 : 0;
$XML::Schema::Instance::DEBUG = $DEBUG ? 2 : 0;
$XML::Schema::Content::DEBUG = $DEBUG ? 3 : 0;
$XML::Schema::Handler::Complex::DEBUG = $DEBUG ? 4 : 0;
$XML::Schema::Handler::Simple::DEBUG = $DEBUG ? 4 : 0;

my $package = 'XML::Schema::Type::string';
my $string = $package->new( );
$string->constrain( maxLength => 12 );
ok( $string, $package->error() );

$package = 'XML::Schema::Handler';
my $handler = $package->new( type => $string );
ok( $handler, $package->error() );
match( $handler->type(), $string );

$package = 'XML::Schema::Handler::Simple';
$handler = $package->new( type => $string );
ok( $handler, $package->error() );
match( $handler->type(), $string );

$package = 'XML::Schema::Instance';
my $instance = $package->new( schema => 'dummy schema' );
ok( $instance, $package->error() );

$handler = $instance->simple_handler( $string );
ok( $handler, $instance->error() );

my $name  = 'Roger';
ok( ! $handler->start_element($instance, $name, { foo => 1 }) );
match( $handler->error(), 'simple element type cannot contain attributes' );

ok( $handler->start_element($instance, $name), $handler->error() );
ok( ! $handler->start_child() );
match( $handler->error(), 'simple element type cannot contain child elements' );
ok( $handler->text($instance, 'The cat sat') );

my $result = $handler->end_element($instance, $name);
ok( $result, $handler->error() );
match( $result->{ result }, 'The cat sat' );

ok( $handler->start_element($instance, $name), $handler->error() );
ok( $handler->text($instance, 'The cat sat on the mat') );
$result = $handler->end_element($instance, $name);
ok( ! $result );
match( $handler->error(), 'string has 22 characters (required maxLength: 12)' );


#------------------------------------------------------------------------
# scheduling

ok( $string->schedule_instance(\&munge_string) );
ok( $handler->schedule_instance(\&munge_animal) );

sub munge_string {
    my ($handler, $infoset) = @_;
    print STDERR "munge_string($infoset->{ result })\n" if $DEBUG;
    $infoset->{ result } = "<string>$infoset->{ result }</string>";
}

sub munge_animal {
    my ($handler, $infoset) = @_;
    print STDERR "munge_animal($infoset->{ result })\n" if $DEBUG;
    $infoset->{ result } = "<animal>$infoset->{ result }</animal>";
}

ok( $handler->start_element($instance, $name), $handler->error() );
ok( $handler->text($instance, 'camel') );
$result = $handler->end_element($instance, $name);
ok( $result );
match( $result->{ result }, '<animal><string>camel</string></animal>' );



#------------------------------------------------------------------------
$package = 'XML::Schema::Type::Complex';

my $complex = $package->new( empty => 1 );
ok( $complex, $package->error() );
$complex->attribute( name => 'id', type => $string );
$complex->attribute( name => 'lang', type => $string, default => 'EN' );


$package = 'XML::Schema::Handler::Complex';
$handler = $package->new( type => $complex );
ok( ! $handler );
match( $package->error(), "XML::Schema::Handler::Complex: element not specified");

my $element = XML::Schema::Element->new( name => 'test', type => $complex );
$handler = $package->new( type => $complex , element => $element );
ok( $handler, $package->error() );

ok( ! $handler->start_element('instance', 'element_name', { foo => 'bar' }) );
match( $handler->error(), 'unexpected attribute: foo' );


ok( ! $handler->start_element('instance', 'element_name', 
			      { foo => 'bar', boz => 'baz', wiz => 'woz' }) );
match( $handler->error(), 'unexpected attributes: boz, foo, wiz' );

ok( $handler->start_element('instance', 'element_name', {  }),
    $handler->error() );
#match( $handler->error(), 'id attribute: no value defined' );

ok( $handler->start_element('instance', 'element_name', { id => 'foo' }),
    $handler->error() );

my $attribs = $handler->attributes();
ok( $attribs, $handler->error() );
match( $attribs->{ id }, '<string>foo</string>' );
match( $attribs->{ lang }, '<string>EN</string>' );

ok( $handler->start_element('instance', 'element_name', { id => 'foo', lang => 'DE' }) );
$attribs = $handler->attributes();
ok( $attribs, $handler->error() );
match( $attribs->{ id }, '<string>foo</string>' );
match( $attribs->{ lang }, '<string>DE</string>' );

my $attrib = $complex->attribute('lang');
ok( $attrib, $complex->error() );

ok( $attrib->schedule_instance(\&munge_lang) );

sub munge_lang {
    my ($handler, $infoset) = @_;
    print STDERR "munge_lang($infoset->{ result })\n" if $DEBUG;
    $infoset->{ result } =~ s/EN/EN_UK/;
}

ok( $handler->start_element('instance', 'element_name', { id => 'bar' }) );
$attribs = $handler->attributes();
ok( $attribs, $handler->error() );
match( $attribs->{ id }, '<string>bar</string>' );
match( $attribs->{ lang }, '<string>EN_UK</string>' );

#------------------------------------------------------------------------
$package = 'XML::Schema::Type::string';
$string = $package->new( );
ok( $string );
$string->constrain( maxLength => 12 );

$package = 'XML::Schema::Attribute';

my $foo = $package->new( name => 'foo', type => $string );
my $bar = { name => 'bar', type => $string };

$package = 'XML::Schema::Type::Complex';

$complex = $package->new( attributes => { foo => $foo, bar => $bar },
			  empty => 1 );
ok( $complex, $package->error() );

my $fooref = $complex->attribute('foo');
match( $fooref, $foo );

my $barref = $complex->attribute('bar');
my $factory = $XML::Schema::FACTORY;
ok( $factory->isa( attribute => $barref ) );

