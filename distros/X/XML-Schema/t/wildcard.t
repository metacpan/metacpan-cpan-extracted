#!/usr/bin/perl -w
#============================================================= -*-perl-*-
#
# t/wildcard.t
#
# Test the XML::Schema::Wildcard module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: wildcard.t,v 1.2 2001/12/20 13:26:28 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Wildcard;
use XML::Schema::Constants qw( :wildcard );
$^W = 1;

my $DEBUG = grep(/-d/, @ARGV);
$XML::Schema::Wildcard::DEBUG = $DEBUG;

ntests(71);

my $pkg = 'XML::Schema::Wildcard';
my $card = $pkg->new();
ok( ! $card );
match( $pkg->error(), 'no namespace specified' );

$card = $pkg->new( any => 1 );
ok( $card, $pkg->error() );
ok( $card->accept('foo') );
ok( $card->accept('foo:bar') );
ok( $card->accept('foo_bar-baz.blam:bar') );
match( $card->select(), ANY );

$card = $pkg->new( namespace => 'any' );
ok( $card, $pkg->error() );
ok( $card->accept('foo') );
ok( $card->accept('foo:bar') );
ok( $card->accept('foo_bar-baz.blam:bar') );
match( $card->select(), ANY );

$card = $pkg->new( namespace => ANY );
ok( $card, $pkg->error() );
ok( $card->accept('foo') );
ok( $card->accept('foo:bar') );
ok( $card->accept('foo_bar-baz.blam:bar') );
match( $card->select(), ANY );

$card = $pkg->new( not => 'pants' );
ok( $card, $pkg->error() );
ok( $card->accept('foo') );
ok( $card->accept('foo:bar') );
ok( ! $card->accept('pants:foo') );
ok( $card->accept('underpants:foo') );
match( $card->select(), NOT );

$card = $pkg->new( namespace => [ not => 'pants' ] );
ok( $card, $pkg->error() );
ok( $card->accept('foo') );
ok( $card->accept('foo:bar') );
ok( $card->accept('foo_bar-baz.blam:bar') );
ok( ! $card->accept('pants:foo') );
ok( $card->accept('underpants:foo') );
match( $card->select(), NOT );
match( $card->namespace(), 'pants' );

$card = $pkg->new( namespace => [ NOT, 'pants' ] );
ok( $card, $pkg->error() );
ok( $card->accept('foo') );
ok( $card->accept('pants') );
ok( $card->accept('foo:bar') );
ok( $card->accept('foo_bar-baz.blam:bar') );
ok( ! $card->accept('pants:foo') );
ok( $card->accept('underpants:foo') );
match( $card->select(), NOT );
match( $card->namespace(), 'pants' );

$card = $pkg->new( namespace => 'pants' );
ok( $card, $pkg->error() );
ok( ! $card->accept('foo') );
ok( ! $card->accept('pants') );
ok( ! $card->accept('foo:bar') );
ok( ! $card->accept('foo_bar-baz.blam:bar') );
ok( $card->accept('pants:foo') );
ok( ! $card->accept('underpants:foo') );
match( $card->select(), ONE );
match( $card->namespace()->{ pants }, 1 );

$card = $pkg->new( namespace => ['pants', 'underpants'] );
ok( $card, $pkg->error() );
ok( ! $card->accept('foo') );
ok( ! $card->accept('pants') );
ok( ! $card->accept('foo:bar') );
ok( ! $card->accept('foo_bar-baz.blam:bar') );
ok( $card->accept('pants:foo') );
ok( $card->accept('underpants:foo') );
match( $card->select(), ONE );
match( $card->namespace()->{ pants }, 1 );
match( $card->namespace()->{ underpants }, 1 );

$card = $pkg->new( namespace => NOT );
ok( $card, $pkg->error() );
ok( ! $card->accept('foo') );
ok( ! $card->accept('pants') );
ok( $card->accept('foo:bar') );
ok( $card->accept('foo_bar-baz.blam:bar') );
ok( $card->accept('pants:foo') );
ok( $card->accept('underpants:foo') );
match( $card->select(), NOT );

$card = $pkg->new( namespace => NOT, process => 'wank' );
ok( ! $card );
match( $pkg->error(), "wildcard process must be 'skip', 'lax' or 'strict' (not 'wank')" );

$card = $pkg->new( namespace => NOT, process => 'skip' );
ok( $card );
match( $card->process(), "skip" );



