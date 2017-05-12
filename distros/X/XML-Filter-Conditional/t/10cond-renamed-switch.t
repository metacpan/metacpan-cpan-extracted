#!/usr/bin/perl -w

use strict;

use Test::More tests => 91;

use XML::SAX::ParserFactory;

use t::MockXMLSAXConsumer;

package t::XMLFilterTest;

use base qw( XML::Filter::Conditional );

push @t::MockXMLSAXConsumer::CAPTURE, qw( store_switch eval_case );

sub store_switch
{
   my $self = shift;
   my ( $e ) = @_;

   $self->{Handler}->store_switch( $e );

   return "intermediate";
}

sub eval_case
{
   my $self = shift;
   my ( $switch, $e ) = @_;

   $self->{Handler}->eval_case( $switch, $e );

   return $e->{Attributes}{'{}value'}{Value} == 1;
}

package main;

# Set up the XML object chain

my $out = t::MockXMLSAXConsumer->new();
my $filter = t::XMLFilterTest->new( 
   Handler => $out,

   SwitchTag    => 'given',
   CaseTag      => 'when',
   OtherwiseTag => 'alternatively',
);
my $parser = XML::SAX::ParserFactory->parser( Handler => $filter );

$parser->parse_string( <<EOXML );
<test>
  <switch test="1">
    <case value="1">One</case>
    <case value="2">Two</case>
  </switch>
  <given test="1">
    <when value="1">One</when>
    <when value="2">Two</when>
  </given>
</test>
EOXML

my @methods;

@methods = $out->GET_LOG;

my $m;

# ->start_element ( { Name => 'test' } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'test' );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "\n  " );

# ->start_element( { Name => 'switch' with attrs } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'switch' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}test' ] );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "\n    " );

# ->start_element( { Name => 'case' with attrs } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'case' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}value' ] );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "One" );

# ->end_element( { Name => 'case' } )
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'case' );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "\n    " );

# ->start_element( { Name => 'case' with attrs } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'case' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}value' ] );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "Two" );

# ->end_element( { Name => 'case' } )
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'case' );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "\n  " );

# ->end_element( { Name => 'switch' } )
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'switch' );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "\n  " );

# ->store_switch ( { Name => 'given' with attrs } )
$m = shift @methods;
is( $m->[0],       'store_switch' );
is( $m->[1]{Name}, 'given' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}test' ] );
is( $m->[1]{Attributes}{'{}test'}{Value}, '1' );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n    " } ] );

# ->eval_case "intermediate", { when with attrs }
$m = shift @methods;
is( $m->[0],       'eval_case' );
is( $m->[1],       'intermediate' );
is( $m->[2]{Name}, 'when' );
is_deeply( [ keys %{ $m->[2]{Attributes} } ], [ '{}value' ] );
is( $m->[2]{Attributes}{'{}value'}{Value}, '1' );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "One\n    \n  \n" );

# ->end_element
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'test' );

is( scalar @methods, 0 );

$parser->parse_string( <<EOXML );
<test>
  <switch test="1">
    <case value="2">Two</case>
    <otherwise>Otherwise</otherwise>
  </switch>
  <given test="1">
    <when value="2">Two</when>
    <alternatively>Alternatively</alternatively>
  </given>
</test>
EOXML

@methods = $out->GET_LOG;

# ->start_element ( { Name => 'test' } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'test' );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "\n  " );

# ->start_element( { Name => 'switch' with attrs } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'switch' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}test' ] );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "\n    " );

# ->start_element( { Name => 'case' with attrs } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'case' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}value' ] );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "Two" );

# ->end_element( { Name => 'case' } )
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'case' );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "\n    " );

# ->start_element( { Name => 'otherwise' no attrs } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'otherwise' );
is( scalar keys %{ $m->[1]{Attributes} }, 0 );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "Otherwise" );

# ->end_element( { Name => 'otherwise' } )
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'otherwise' );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "\n  " );

# ->end_element( { Name => 'switch' } )
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'switch' );

# ->characters
$m = shift @methods;
is( $m->[0],       'characters' );
is( $m->[1]{Data}, "\n  " );

# ->store_switch ( { Name => 'given' with attrs } )
$m = shift @methods;
is( $m->[0],       'store_switch' );
is( $m->[1]{Name}, 'given' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}test' ] );
is( $m->[1]{Attributes}{'{}test'}{Value}, '1' );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n    " } ] );

# ->eval_case "intermediate", { when with attrs }
$m = shift @methods;
is( $m->[0],       'eval_case' );
is( $m->[1],       'intermediate' );
is( $m->[2]{Name}, 'when' );
is_deeply( [ keys %{ $m->[2]{Attributes} } ], [ '{}value' ] );
is( $m->[2]{Attributes}{'{}value'}{Value}, '2' );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n    Alternatively\n  \n" } ] );

$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'test' );

is( scalar @methods, 0 );
