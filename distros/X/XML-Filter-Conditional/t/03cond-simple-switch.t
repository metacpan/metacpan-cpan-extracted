#!/usr/bin/perl -w

use strict;

use Test::More tests => 50;

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
my $filter = t::XMLFilterTest->new( Handler => $out );
my $parser = XML::SAX::ParserFactory->parser( Handler => $filter );

# XML::SAX::PurePerl up to 0.91 can't cope with Processing Instructions. It 
# yields the wrong values for ->{target} and ->{data}
# See: https://rt.cpan.org/Ticket/Display.html?id=19173
my $parser_broken_PIs;
{
   no strict 'refs';
   # Horrible softref is required here, to avoid needlessly creating the
   # package if it doesn't already exist. If we don't do this, the
   # ParserFactory gets annoyed
   $parser_broken_PIs = $parser->isa( "XML::SAX::PurePerl" ) && ${"XML::SAX::PurePerl::VERSION"} <= '0.91';
}

$parser->parse_string( <<EOXML );
<test>
  <switch test="1">
    <case value="1">One<node name="one"/><!-- comment one --><?process one?></case>
    <case value="2">Two<node name="two"/><!-- comment two --><?process two?></case>
  </switch>
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
is_deeply( $m, [ 'characters', { Data => "\n  " } ] );

# ->store_switch ( { Name => 'switch' with attrs } )
$m = shift @methods;
is( $m->[0],       'store_switch' );
is( $m->[1]{Name}, 'switch' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}test' ] );
is( $m->[1]{Attributes}{'{}test'}{Value}, '1' );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n    " } ] );

# ->eval_case "intermediate", { case with attrs }
$m = shift @methods;
is( $m->[0],       'eval_case' );
is( $m->[1],       'intermediate' );
is( $m->[2]{Name}, 'case' );
is_deeply( [ keys %{ $m->[2]{Attributes} } ], [ '{}value' ] );
is( $m->[2]{Attributes}{'{}value'}{Value}, '1' );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "One" } ] );

# ->start_element
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'node' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}name' ] );
is( $m->[1]{Attributes}{'{}name'}{Value}, 'one' );

# ->end_element
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'node' );

# ->comment
$m = shift @methods;
is_deeply( $m, [ 'comment', { Data => " comment one " } ] );

# ->processing_instruction
$m = shift @methods;
SKIP: {
   skip "Processing Instruction", 1 if $parser_broken_PIs;

   is_deeply( $m, [ 'processing_instruction', { Target => 'process', Data => 'one' } ] );
}

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n    \n  \n" } ] );

# ->end_element
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'test' );

is( scalar @methods, 0 );

$parser->parse_string( <<EOXML );
<test>
  <switch test="1">
    <case value="2">Two</case>
    <case value="3">Three</case>
    <otherwise>Otherwise</otherwise>
  </switch>
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

# ->store_switch ( { Name => 'switch' with attrs } )
$m = shift @methods;
is( $m->[0],       'store_switch' );
is( $m->[1]{Name}, 'switch' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}test' ] );
is( $m->[1]{Attributes}{'{}test'}{Value}, '1' );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n    " } ] );

# ->eval_case "intermediate", { case with attrs }
$m = shift @methods;
is( $m->[0],       'eval_case' );
is( $m->[1],       'intermediate' );
is( $m->[2]{Name}, 'case' );
is_deeply( [ keys %{ $m->[2]{Attributes} } ], [ '{}value' ] );
is( $m->[2]{Attributes}{'{}value'}{Value}, '2' );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n    " } ] );

# ->eval_case "intermediate", { case with attrs }
$m = shift @methods;
is( $m->[0],       'eval_case' );
is( $m->[1],       'intermediate' );
is( $m->[2]{Name}, 'case' );
is_deeply( [ keys %{ $m->[2]{Attributes} } ], [ '{}value' ] );
is( $m->[2]{Attributes}{'{}value'}{Value}, '3' );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n    Otherwise\n  \n" } ] );

$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'test' );

is( scalar @methods, 0 );
