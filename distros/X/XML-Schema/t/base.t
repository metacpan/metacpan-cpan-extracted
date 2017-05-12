#============================================================= -*-perl-*-
#
# t/base.t
#
# Test the XML::Schema::Base.pm module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: base.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

$^W = 1;

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Base;

#$XML::Schema::Base::DEBUG = 1;

### NOTE: don't forget to update this value or comment it out ###
ntests(128);

my ($pkg, $mod);


#------------------------------------------------------------------------
# XML::Schema::Test::Fail always fails, but we check it reports errors OK

package XML::Schema::Test::Fail;
use base qw( XML::Schema::Base );
use vars qw( $ERROR );

sub init {
    my $self = shift;
    return $self->error('expected failure');
}

package main;

# instantiate a base class object and test error reporting/returning
$mod = XML::Schema::Base->new();
ok( $mod );
ok( ! defined $mod->error('barf') );
ok( $mod->error() eq 'barf' );

# XML::Schema::Fail should never work, but we check it reports errors OK
$pkg = 'XML::Schema::Test::Fail';
ok( ! $pkg->new() );
match( $pkg->error, 'expected failure' );
match( $XML::Schema::Test::Fail::ERROR, 'expected failure' );


#------------------------------------------------------------------------
# XML::Schema::Test::Name should only work with a 'name'parameters

package XML::Schema::Test::Name;
use base qw( XML::Schema::Base );
use vars qw( $ERROR );

sub init {
    my ($self, $params) = @_;
    $self->{ NAME } = $params->{ name } 
	|| return $self->error("No name!");
    return $self;
}

sub name {
    $_[0]->{ NAME };
}

package main;

$mod = XML::Schema::Test::Name->new();
ok( ! $mod );
match( $XML::Schema::Test::Name::ERROR, 'No name!' );
match( XML::Schema::Test::Name->error(), 'No name!' );

# give it what it wants...
$mod = XML::Schema::Test::Name->new({ name => 'foo' });
ok( $mod );
ok( ! $mod->error() );
match( $mod->name(), 'foo' );

# ... in 2 different flavours
$mod = XML::Schema::Test::Name->new(name => 'foo');
ok( $mod );
ok( ! $mod->error() );
match( $mod->name(), 'foo' );


#------------------------------------------------------------------------
# XML::Schema::Test::Args expects some @ARGUMENTS

package XML::Schema::Test::Args;
use base qw( XML::Schema::Base );
use vars qw( $ERROR @ARGUMENTS );

@ARGUMENTS = qw( name );

sub new {
    my ($class, @args) = @_;
    my $baseargs = $class->_baseargs('@ARGUMENTS');
    my $argnames = $baseargs->[0];
    $class->error('');

    my $self = bless {
	_ERROR  => '',
    }, $class;

    return $self->_arguments($argnames, \@args)
	|| $class->error($self->error());
}


package main;

$pkg = 'XML::Schema::Test::Args';
$mod = $pkg->new();
ok( ! $mod );
match( $pkg->error(), "$pkg: name not specified" );

$mod = $pkg->new('Aphrodite');
ok( $mod );
ok( ! $mod->error() );
ok( ! $pkg->error(), $pkg->error() );
match( $mod->{ name }, 'Aphrodite' );


#------------------------------------------------------------------------
# test multiple (linear) inheritance and ensure all @ARGUMENTS get picked
# up in the right order

package XML::Schema::Test::Args::Foo;
use base qw( XML::Schema::Test::Args );
use vars qw( $ERROR @ARGUMENTS );

@ARGUMENTS = qw( age real_age );

package XML::Schema::Test::Args::Bar;
use base qw( XML::Schema::Test::Args );
use vars qw( $ERROR @ARGUMENTS );

@ARGUMENTS = qw( height width );

package XML::Schema::Test::Args::FooBar;
use base qw( XML::Schema::Test::Args::Foo 
             XML::Schema::Test::Args::Bar );
use vars qw( $ERROR @ARGUMENTS );

@ARGUMENTS = qw( serial );


package main;

$pkg = 'XML::Schema::Test::Args::FooBar';

$mod = $pkg->new();
ok( ! $mod );
match( $pkg->error(), "$pkg: name not specified" );

$mod = $pkg->new('fred');
ok( ! $mod );
match( $pkg->error(), "$pkg: age not specified" );

$mod = $pkg->new('fred', 21);
ok( ! $mod );
match( $pkg->error(), "$pkg: real_age not specified" );

$mod = $pkg->new('fred', 21, 36);
ok( ! $mod );
match( $pkg->error(), "$pkg: height not specified" );

$mod = $pkg->new('fred', 21, 36, 1.76);
ok( ! $mod );
match( $pkg->error(), "$pkg: width not specified" );

$mod = $pkg->new('fred', 21, 36, 1.76, 42);
ok( ! $mod );
match( $pkg->error(), "$pkg: serial not specified" );

$mod = $pkg->new('fred', 21, 36, 1.76, 42, 'pi314e2718');
ok( $mod );
match( $mod->{ name }, 'fred' );
match( $mod->{ age }, 21 );
match( $mod->{ real_age }, 36 );
match( $mod->{ height }, 1.76 );
match( $mod->{ width }, 42 );
match( $mod->{ serial }, 'pi314e2718' );


#------------------------------------------------------------------------
# test _mandatory() method

package XML::Schema::Test::Mandy;
use base qw( XML::Schema::Base );

sub init {
    my ($self, $config) = @_;
    my $base = $self->_baseargs('@MANDATORY');
    $self->_mandatory($base->[0], $config);
}

package XML::Schema::Test::Mandy::Foo;
use base qw( XML::Schema::Test::Mandy );
use vars qw( @MANDATORY );

@MANDATORY = qw( one two );

package XML::Schema::Test::Mandy::Bar;
use base qw( XML::Schema::Test::Mandy::Foo );
use vars qw( @MANDATORY );

@MANDATORY = qw( zen zoo );


package main;

$pkg = 'XML::Schema::Test::Mandy';
$mod = $pkg->new();
ok( $mod );

$pkg = 'XML::Schema::Test::Mandy::Foo';
$mod = $pkg->new();
ok( ! $mod );
match( $pkg->error(), "$pkg: one not specified" );

$mod = $pkg->new( one => 'hello' );
ok( ! $mod );
match( $pkg->error(), "$pkg: two not specified" );

$mod = $pkg->new( one => 'hello', two => 'world' );
ok( $mod );
match( $mod->{ one }, 'hello' );
match( $mod->{ two }, 'world' );


$pkg = 'XML::Schema::Test::Mandy::Bar';
$mod = $pkg->new();
ok( ! $mod );
match( $pkg->error(), "$pkg: one not specified" );

$mod = $pkg->new( one => 'hello', two => 'world' );
ok( ! $mod );
match( $pkg->error(), "$pkg: zen not specified" );

$mod = $pkg->new( 
    one => 'hello', two => 'world', zen => 'meaning', zoo => 'life'
);
ok( $mod );
match( $mod->{ one }, 'hello' );
match( $mod->{ two }, 'world' );
match( $mod->{ zen }, 'meaning' );
match( $mod->{ zoo }, 'life' );


#------------------------------------------------------------------------
# test _optional() method

package XML::Schema::Test::MandyOpt;
use base qw( XML::Schema::Base );

sub init {
    my ($self, $config) = @_;
    my $base = $self->_baseargs('@MANDATORY', '%OPTIONAL');
    $self->_mandatory($base->[0], $config)
	|| return;
    $self->_optional($base->[1], $config)
	|| return;
}

package XML::Schema::Test::MandyOpt::Foo;
use base qw( XML::Schema::Test::MandyOpt );
use vars qw( @MANDATORY %OPTIONAL );

@MANDATORY = qw( x y );
%OPTIONAL  = ( z => 'Zulu' );

package XML::Schema::Test::MandyOpt::Bar;
use base qw( XML::Schema::Test::MandyOpt );
use vars qw( @MANDATORY %OPTIONAL );

@MANDATORY = qw( a b );
%OPTIONAL  = ( c => 'Charlie' );

package XML::Schema::Test::MandyOpt::FooBar;
use base qw( XML::Schema::Test::MandyOpt::Foo
	     XML::Schema::Test::MandyOpt::Bar );
use vars qw( @MANDATORY %OPTIONAL );

my $count  = 1;
%OPTIONAL  = ( d => 'Delta', n => sub { $count++ } );


package main;

$pkg = 'XML::Schema::Test::MandyOpt::Foo';
$mod = $pkg->new();
ok( ! $mod );
match( $pkg->error(), "$pkg: x not specified" );

$mod = $pkg->new( x => 'X-Ray' );
ok( ! $mod );
match( $pkg->error(), "$pkg: y not specified" );

$mod = $pkg->new( x => 'X-Ray', y => 'Yankee' );
ok( $mod );
match( $mod->{ x }, 'X-Ray' );
match( $mod->{ y }, 'Yankee' );
match( $mod->{ z }, 'Zulu' );

$mod = $pkg->new( x => 'X-Ray', y => 'Yankee', z => 'Zebra' );
ok( $mod );
match( $mod->{ x }, 'X-Ray' );
match( $mod->{ y }, 'Yankee' );
match( $mod->{ z }, 'Zebra' );


$pkg = 'XML::Schema::Test::MandyOpt::Bar';
$mod = $pkg->new();
ok( ! $mod );
match( $pkg->error(), "$pkg: a not specified" );

$mod = $pkg->new( a => 'Alpha', b => 'Bravo' );
ok( $mod, $pkg->error() );
match( $mod->{ a }, 'Alpha' );
match( $mod->{ b }, 'Bravo' );
match( $mod->{ c }, 'Charlie' );

$mod = $pkg->new( a => 'Andy', b => 'Ben', c => 'Craig' );
ok( $mod );
match( $mod->{ a }, 'Andy' );
match( $mod->{ b }, 'Ben' );
match( $mod->{ c }, 'Craig' );


$pkg = 'XML::Schema::Test::MandyOpt::FooBar';
$mod = $pkg->new();
ok( ! $mod );
match( $pkg->error(), "$pkg: x not specified" );

$mod = $pkg->new( x => 'X-Ray', y => 'Yankee', 
		  a => 'Alpha', b => 'Bravo' );

ok( $mod, $pkg->error() );
match( $mod->{ x }, 'X-Ray' );
match( $mod->{ y }, 'Yankee' );
match( $mod->{ a }, 'Alpha' );
match( $mod->{ b }, 'Bravo' );
match( $mod->{ c }, 'Charlie' );
match( $mod->{ d }, 'Delta' );
match( $mod->{ n }, 1 );

$mod = $pkg->new( x => 'Xavier', y => 'Yanis', 
		  a => 'Andy',   b => 'Ben', 
		  c => 'Craig',  d => 'Dan' );
ok( $mod );
match( $mod->{ x }, 'Xavier' );
match( $mod->{ y }, 'Yanis' );
match( $mod->{ a }, 'Andy' );
match( $mod->{ b }, 'Ben' );
match( $mod->{ c }, 'Craig' );
match( $mod->{ d }, 'Dan' );
match( $mod->{ n }, 2 );

my @args = map { ($_, uc $_) } qw( x y a b c d );
$mod = $pkg->new( @args, n => 12345 );
ok( $mod );
match( $mod->{ n }, 12345 );

$mod = $pkg->new( @args );
ok( $mod );
match( $mod->{ n }, 3 );

$mod = $pkg->new( @args );
ok( $mod );
match( $mod->{ n }, 4 );


#------------------------------------------------------------------------
# test error_value() method

ok( ! $mod->error_value('thing', 'voidular', 'foo', 'bar', 'baz') );
match( $mod->error(),
       "thing must be 'foo', 'bar' or 'baz' (not 'voidular')" );


#------------------------------------------------------------------------
# test factory() method

package XML::Schema::Test::Factory;
use base qw( XML::Schema::Base );

package main;

$pkg = 'XML::Schema::Test::Factory';

$mod = $pkg->new( factory => 'foo bar' );
ok( $mod );
match( $mod->factory, 'foo bar' );

$mod = $pkg->new( FACTORY => 'foo baz' );
ok( $mod );
match( $mod->factory, 'foo baz' );

$mod->factory('wiz woz');
match( $mod->factory, 'wiz woz' );

$mod = $pkg->new( );
ok( $mod );
match( $mod->factory, 'XML::Schema::Factory' );

$XML::Schema::FACTORY = 'new factory';
ok( $mod );
match( $mod->factory, 'new factory' );

$XML::Schema::FACTORY = 'XML::Schema::Factory';


#------------------------------------------------------------------------
# test throw()

package XML::Schema::Test::Throw;
use base qw( XML::Schema::Base );
use vars qw( $ETYPE );
$ETYPE = 'hello';

package main;

$pkg = 'XML::Schema::Test::Throw';
$mod = $pkg->new();
ok( $mod );

my $factory = $mod->factory;
match( $factory, 'XML::Schema::Factory' );
my $e = $factory->create( exception => 'random', 'message' );
ok( $e );
match( $e->type(), 'random' );
match( $e->info(), 'message' );

eval { $mod->throw($e) };
$e = $@;
match( $e->type(), 'random' );
match( $e->info(), 'message' );

eval { $mod->throw('world') };
$e = $@;
match( $e->type(), 'hello' );
match( $e->info(), 'world' );

eval { $mod->throw( over => 'there' ) };
$e = $@;
match( $e->type(), 'over' );
match( $e->info(), 'there' );


package XML::Schema::Test::Throw2;
use base qw( XML::Schema::Base );

package main;

$pkg = 'XML::Schema::Test::Throw2';
$mod = $pkg->new();
ok( $mod );


eval { $mod->throw('ping') };
$e = $@;
match( $e->type(), 'undef' );
match( $e->info(), 'ping' );
