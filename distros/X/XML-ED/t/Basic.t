#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

use_ok( 'XML::ED::Bare', qw/xmlin/ );

my $xml;
my $root;
my $simple;

( $xml, $root ) = XML::ED::Bare->new( text => "<xml><node>val</node></xml>" );

( $xml, $root ) = XML::ED::Bare->new( text => "<xml><node/></xml>" );

( $xml, $root ) = XML::ED::Bare->new( text => "<xml><node att=12>val</node></xml>" );

( $xml, $root ) = XML::ED::Bare->new( text => "<xml><node att=\"12\">val</node></xml>" );

( $xml, $root ) = XML::ED::Bare->new( text => "<xml><node><![CDATA[<cval>]]></node></xml>" );

( $xml, $root ) = XML::ED::Bare->new( text => "<xml><node>a</node><node>b</node></xml>" );

( $xml, $root ) = XML::ED::Bare->new( text => "<xml><multi_node/><node>a</node></xml>" );

( $xml, $root ) = XML::ED::Bare->new( text => "<xml><node>val<a/></node></xml>" );

( $xml, $root ) = XML::ED::Bare->new( text => "<xml><node><a/>val</node></xml>" );

( $xml, $root ) = XML::ED::Bare->new( text => "<xml><!--test--></xml>" );

( $xml, $root ) = XML::ED::Bare->new( text => "<xml></xml>" );

my $text = '<xml><node>checkval</node></xml>';
( $xml, $root ) = new XML::ED::Bare( text => $text );
use Data::Dumper;
print Dumper $root;

sub cyclic {
  my ( $text, $name ) = @_;
  ( $xml, $root ) = XML::ED::Bare->( text => $text );
  my $a = $xml->xml( $root );
  ( $xml, $root ) = XML::ED::Bare->( text => $a );
  my $b = $xml->xml( $root );
  is( $a, $b, "cyclic - $name" );
}

# test bad closing tags
# we need to a way to ensure that something dies... ?

( $xml, $root, $simple ) = XML::ED::Bare->new( text => "<xml><node>val</node><value>value</value> value </xml>" );

done_testing();
