# $Id: 1_buffer.t,v 1.2 2005/04/20 20:03:52 grantm Exp $

use strict;
use Test::More;

BEGIN { # Seems to be required by older Perls

  unless(eval { require XML::SAX::Writer }) {
    plan skip_all => 'XML::SAX::Writer not installed';
  }

  unless(eval { require XML::SAX::ParserFactory }) {
    plan skip_all => 'XML::SAX::ParserFactory not installed';
  }

}

plan tests => 17;

$^W = 1;


##############################################################################
# Confirm that the module compiles
#

use XML::Filter::Sort::Buffer;

ok(1, 'XML::Filter::Sort::Buffer compiled OK');


##############################################################################
# Try creating a Buffer object
#

my $buffer = XML::Filter::Sort::Buffer->new(
  Keys => [
            [ '.', 'a', 'a' ]  # All text alpha ascending
	  ]
);

ok(ref($buffer), 'Created a buffer object');
isa_ok($buffer, 'XML::Filter::Sort::Buffer');


##############################################################################
# Poke some SAX events into it, close it and confirm the sort key value was
# extracted correctly.
#

my $rec_elem = {
  Name         => 'record',
  LocalName    => 'record',
  Prefix       => '',
  NamespaceURI => '',
  Attributes   => {},
};

$buffer->start_element($rec_elem);
$buffer->characters({ Data => 'text content'});
$buffer->end_element($rec_elem);

my($keyval) = $buffer->close();

is($keyval, 'text content', 'Extracted sort key value from element content');


##############################################################################
# Spool the buffered contents out via SAX to a Writer and confirm it is what
# we expected.
#

my $xmlout = '';
my $writer = XML::SAX::Writer->new(Output => \$xmlout);
$writer->start_document();
$buffer->to_sax($writer);
$writer->end_document();
is($xmlout, '<record>text content</record>', 'Simple XML buffered OK');


##############################################################################
# Now try again but with sort key value in an attribute
#

$buffer = XML::Filter::Sort::Buffer->new(
  Keys => [
            [ './@height', 'n', 'a' ]  # value of 'height' attribute
	  ]
);

$rec_elem->{Attributes} = {
  '{}width'   => {
		    Name         => 'width',
		    LocalName    => 'width',
		    Prefix       => '',
		    NamespaceURI => '',
		    Value        => '1024',
                 },
  '{}height'  => {
		    Name         => 'height',
		    LocalName    => 'height',
		    Prefix       => '',
		    NamespaceURI => '',
		    Value        => '768',
                 },
};

$buffer->characters({ Data => '  '});
$buffer->start_element($rec_elem);
$buffer->characters({ Data => 'text content'});
$buffer->end_element($rec_elem);

($keyval) = $buffer->close();

is($keyval, '768', 'Extracted sort key value from attribute');


##############################################################################
# Make sure it comes back out as expected XML
#

$xmlout = '';
$writer = XML::SAX::Writer->new(Output => \$xmlout);
$writer->start_document();
$buffer->to_sax($writer);
$writer->end_document();
$xmlout =~ s/"/'/sg;
like($xmlout,
     qr{^  <record(\s+width='1024'|\sheight='768'){2}>text content</record>},
     'XML containing attributes returned OK'
);


##############################################################################
# Try creating a Buffer object configured with multiple (3) sort keys.  This
# time use a parser to generate SAX events rather than doing it manually.
# Confirm correct sort key values were extracted and that output from the
# buffer exactly matches the input.
#

my $xmlin = q(<person>
  <firstname>Zebedee</firstname>
  <lastname>Boozle</lastname>
  <age unit='year'>35</age>
  <empty />
  <zero>0</zero>
</person>);

my(@keyvals);
($buffer, @keyvals) = buffer_from_xml(
  [
    [ './lastname',  'a', 'a' ],
    [ './firstname', 'a', 'a' ],
    [ './age',       'a', 'a' ],
  ],
  $xmlin
);

is_deeply(\@keyvals, [qw(Boozle Zebedee 35)], 'Multiple sort keys returned OK');

$xmlout = xml_from_buffer($buffer);
$xmlout =~ s/"year"/'year'/;
$xmlout =~ s{/></empty>}{/>};
$xmlout =~ s{<empty/>}{<empty />};

is($xmlout, $xmlin, 'Round-tripped XML containing elements and attributes');


##############################################################################
# Throw an XML comment into the mix.  Confirm that the key value extraction
# mechanism ignores the comment contents (obviously) and also that the
# comment is correctly buffered and regurgitated.
#

$xmlin = q(<person>
  <!-- Commented out element
    <firstname>Zebedee</firstname>
  -->
  <firstname>Dougal</firstname>
  <lastname>Boozle</lastname>
</person>);

($buffer, @keyvals) = buffer_from_xml(
  [ [ './firstname', 'a', 'a' ], ],
  $xmlin
);

is_deeply(\@keyvals, [qw(Dougal)], 'Ignored value in comment');

$xmlout = xml_from_buffer($buffer, 'simple sort key value');

$xmlout =~ s{&lt;}{<}sg;  # work around (old) XML::SAX::Writer bug
$xmlout =~ s{&gt;}{>}sg;

is($xmlout, $xmlin, 'Round-tripped XML containing a comment');


##############################################################################
# Similar test, but with a Processing Instruction
#

$xmlin = q(<person>
  <?fnurgle x='1'?>
  <firstname>Zebedee</firstname>
  <!-- This is a comment -->
  <lastname>Boozle</lastname>
</person>);

ok(($buffer, @keyvals) = buffer_from_xml(
    [ [ './lastname', 'a', 'a' ], ],
    $xmlin
  ),
  'No crash when presented with PI'
);

is_deeply(\@keyvals, [qw(Boozle)], 'Extracted another simple sort key value');

$xmlout = xml_from_buffer($buffer);

is($xmlout, $xmlin, 'Round-tripped XML containing a Processing Instruction');


##############################################################################
# Ask for matches against non-existant elements confirm we get one empty
# string back for each.
#

$xmlin = q(<person>
  <firstname>Zebedee</firstname>
  <lastname>Boozle</lastname>
</person>);

($buffer, @keyvals) = buffer_from_xml(
  [
    [ './address', 'a', 'a' ],
    [ './email',   'a', 'a' ],
  ],
  $xmlin
);

is_deeply(\@keyvals, ['', ''], 'Correct key values returned when match failed');


##############################################################################
# Now create a buffer configured with a long list of sort keys of varying 
# forms and confirm they all match what we expect them to match.
#

$xmlin = q(
  <person age="12">
    <lastname>Boozle</lastname>
    <firstname initial="Z">Zebedee</firstname>
    <age unit="year" base="10">35</age>
    <empty />
    <alpha><age>100</age><beta>x<gamma>???</gamma><carotine bob="kate"><deep>Fore!</deep></carotine></beta></alpha>
  </person>
);

($buffer, @keyvals) = buffer_from_xml(
  [
    ['lastname'],
    ['firstname'],
    ['age'],
    ['./lastname'],
    ['./alpha/beta/carotine'],
    ['./firstname/@initial'],
    ['firstname/@initial'],
    ['@initial'],
    ['@age'],
    ['@gender'],
    ['alpha/age'],
    ['alpha/beta/gamma'],
    ['alpha/beta'],
  ],
  $xmlin
);

is_deeply(\@keyvals, [
  'Boozle', 'Zebedee', '35', 'Boozle', 'Fore!', 'Z', 'Z', 'Z', 
  12, '', 100, '???', 'x???Fore!'
], 'Longish list of more complex keys');


##############################################################################
# Now do a similar test, but this time with namespaces thrown into the mix.
#

$xmlin = q(
  <person>
    <names xmlns:bob="bob.com">
      <bob:lastname>Smith</bob:lastname>
      <lastname>Jones</lastname>
      <alias xmlns="pat.ie">
	<lastname>O'Toole</lastname>
      </alias>
      <firstname bob:initial="X">Xavier</firstname>
      <firstname initial="Y">Yorick</firstname>
      <alias xmlns:pat="pat.ie">
	<firstname pat:initial="P">Patrick</firstname>
      </alias>
    </names>
  </person>
);

($buffer, @keyvals) = buffer_from_xml(
  [
    ['./names/lastname'],
    ['./names/{}lastname'],
    ['./names/alias/{pat.ie}lastname'],
    ['lastname'],
    ['{}lastname'],
    ['{pat.ie}lastname'],
    ['firstname/@initial'],
    ['firstname/@{}initial'],
    ['firstname/@{pat.ie}initial'],
    ['./names/firstname/@initial'],
    ['./names/firstname/@{}initial'],
    ['./names/alias/firstname/@{pat.ie}initial'],
  ],
  $xmlin
);

is_deeply(\@keyvals, [
  'Smith',
  'Jones',
  'O\'Toole',
  'Smith',
  'Jones',
  'O\'Toole',
  'X',
  'Y',
  'P',
  'X',
  'Y',
  'P',
], 'Keys with namespace elements');


##############################################################################
#                       S U B R O U T I N E S
##############################################################################

sub buffer_from_xml {
  my($keys, $xml) = @_;

  $buffer = XML::Filter::Sort::Buffer->new(Keys => $keys);
  my $parser = XML::SAX::ParserFactory->parser(Handler => $buffer);
  $parser->parse_string($xml);
  my @keyvals = $buffer->close();
  return($buffer, @keyvals);
}


sub xml_from_buffer {
  my($buffer) = @_;

  my $xml = '';
  $writer = XML::SAX::Writer->new(Output => \$xml);
  $writer->start_document();
  $buffer->to_sax($writer);
  $writer->end_document();

  return($xml);
}


