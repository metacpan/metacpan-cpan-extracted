#!/usr/bin/perl -w

use strict;

use Test::More tests => 18;

use XML::SAX::ParserFactory;

use t::MockXMLSAXConsumer;

package t::XMLFilterTest;

use base qw( XML::Filter::Conditional );

sub store_switch
{
   return undef;
}

sub eval_case
{
   return 0;
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
<data>
  Here is some character data
  <node attr="value" />
  <!-- A comment here -->
  <?process obj="self"?>
</data>
EOXML

my @methods;

@methods = $out->GET_LOG;

my $m;

# ->start_element ( { Name => 'data', ... } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'data' );
is_deeply( $m->[1]{Attributes}, {} );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n  Here is some character data\n  " } ] );

# ->start_element ( { Name => 'node' with attrs } )
$m = shift @methods;
is( $m->[0],       'start_element' );
is( $m->[1]{Name}, 'node' );
is_deeply( [ keys %{ $m->[1]{Attributes} } ], [ '{}attr' ] );
is( $m->[1]{Attributes}{'{}attr'}{Value}, 'value' );

# ->end_element ( { Name => 'node', ... } )
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'node' );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n  " } ] );

# ->comment
$m = shift @methods;
is_deeply( $m, [ 'comment', { Data => " A comment here " } ] );

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n  " } ] );

# ->processing_instruction
$m = shift @methods;
SKIP: {
   skip "Processing Instruction", 1 if $parser_broken_PIs;

   is_deeply( $m, [ 'processing_instruction', { Target => 'process', Data => 'obj="self"' } ] );
}

# ->characters
$m = shift @methods;
is_deeply( $m, [ 'characters', { Data => "\n" } ] );

# ->end_element ( { Name => 'data', ... } )
$m = shift @methods;
is( $m->[0],       'end_element' );
is( $m->[1]{Name}, 'data' );

is( scalar @methods, 0 );
