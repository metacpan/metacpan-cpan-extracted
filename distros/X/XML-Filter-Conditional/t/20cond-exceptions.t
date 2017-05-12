#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;
use Test::Exception;

use XML::Filter::Conditional;

use XML::SAX::ParserFactory;

use t::MockXMLSAXConsumer;

package t::XMLFilterTest;

use base qw( XML::Filter::Conditional );

sub store_switch
{
   my $self = shift;
   my ( $e ) = @_;

   return "intermediate";
}

sub eval_case
{
   my $self = shift;
   my ( $switch, $e ) = @_;

   return $e->{Attributes}{'{}value'}{Value} == 1;
}

package main;

# Set up the XML object chain

my $out = t::MockXMLSAXConsumer->new();
my $filter = t::XMLFilterTest->new( Handler => $out );
my $parser = XML::SAX::ParserFactory->parser( Handler => $filter );

throws_ok( sub {
      $parser->parse_string( <<EOXML );
<test>
  <case value="1">One</case>
  <case value="2">Two</case>
</test>
EOXML
   },
   qr/^Found a <case> element outside of a containing switch\s/,
   'Bare <case> element fails' );

# XML::SAX::Expat has a bug, where if the filter chain throws an exception,
# the internal state is not cleanly fixed up, and subsequent uses of the same
# object will fail. To get around this, we'll re-construct a new parser object
# every time
$parser = XML::SAX::ParserFactory->parser( Handler => $filter );

throws_ok( sub {
      $parser->parse_string( <<EOXML );
<test>
  <otherwise>Zero</otherwise>
</test>
EOXML
   },
   qr/^Found a <otherwise> element outside of a containing switch\s/,
   'Bare <otherwise> element fails' );

$parser = XML::SAX::ParserFactory->parser( Handler => $filter );

throws_ok( sub {
      $parser->parse_string( <<EOXML );
<test>
  <switch test="num">
    <case value="1">
      <case value="1">One</case>
    </case>
  </switch>
</test>
EOXML
   },
   qr/^Found a <case> element nested within another\s/,
   'Nested <case> element fails' );

$parser = XML::SAX::ParserFactory->parser( Handler => $filter );

throws_ok( sub {
      $parser->parse_string( <<EOXML );
<test>
  <switch test="num">
    <otherwise>
      <otherwise>Zero</otherwise>
    </otherwise>
  </switch>
</test>
EOXML
   },
   qr/^Found a <otherwise> element nested within another\s/,
   'Nested <case> element fails' );

$parser = XML::SAX::ParserFactory->parser( Handler => $filter );

throws_ok( sub { XML::Filter::Conditional->new( Handler => $out ); },
           qr/^XML::Filter::Conditional must provide ->\w+\(\) at /,
           'Constructing an abstract class fails' );
