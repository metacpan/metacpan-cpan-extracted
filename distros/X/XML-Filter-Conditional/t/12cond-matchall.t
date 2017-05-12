#!/usr/bin/perl -w

use strict;

use Test::More tests => 14;

use XML::SAX::ParserFactory;

use t::MockXMLSAXConsumer;

package t::XMLFilterTest;

use base qw( XML::Filter::Conditional );

sub store_switch
{
   my $self = shift;
   my ( $e ) = @_;

   return;
}

sub eval_case
{
   my $self = shift;
   my ( $switch, $e ) = @_;

   return $e->{Attributes}{'{}value'}{Value} eq "true";
}

package main;

# Set up the XML object chain

my $out = t::MockXMLSAXConsumer->new();
my $filter = t::XMLFilterTest->new( 
   Handler => $out,
);
my $parser = XML::SAX::ParserFactory->parser( Handler => $filter );

my $testxml = '<test><switch>' .
                 '<case value="true">RED</case>' .
                 '<case value="true">BLUE</case>' .
                 '<case value="false">GREEN</case>' .
                 '<otherwise>YELLOW</otherwise>' .
              '</switch></test>';

$parser->parse_string( $testxml );

my @methods;

@methods = $out->GET_LOG;

my $m;

$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'test' );

$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, 'RED' );

$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'test' );

is( scalar @methods, 0 );

$filter = t::XMLFilterTest->new( 
   Handler => $out,

   MatchAll => 1,
);
$parser = XML::SAX::ParserFactory->parser( Handler => $filter );

$parser->parse_string( $testxml );

@methods = $out->GET_LOG;

$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'test' );

$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, 'REDBLUE' );

$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'test' );

is( scalar @methods, 0 );
