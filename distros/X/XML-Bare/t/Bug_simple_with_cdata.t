#!/usr/bin/perl -w

use strict;

use Test::More qw(no_plan);

use_ok( 'XML::Bare', qw/xmlin/ );

my ( $ob, $root ) = XML::Bare->simple( text => "<node att='2'><![CDATA[cdata contents]]></node>" ); 

ok( $root, "Got some root" );
my $attval = $root->{'node'}{'att'};
is( $attval, '2', "Got the right attribute value" );
my $cdataval = $root->{'node'}{'content'};
is( $cdataval, 'cdata contents', "Got the right cdata value" );