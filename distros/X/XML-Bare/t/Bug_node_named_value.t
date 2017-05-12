#!/usr/bin/perl -w

use strict;

use Test::More qw(no_plan);

use_ok( 'XML::Bare', qw/xmlin/ );

my ( $ob, $root ) = XML::Bare->new( text => qq{<?xml version="1.0"?><value>erower</value>\n} ); 
ok( $root, "Got some root" );
my $val = $root->{'value'}{'value'};
is( $val, 'erower', "Got the right value" );