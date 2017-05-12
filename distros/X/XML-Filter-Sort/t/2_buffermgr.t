# $Id: 2_buffermgr.t,v 1.1.1.1 2002/06/14 20:39:49 grantm Exp $

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

plan tests => 13;

$^W = 1;


##############################################################################
# Confirm that the module compiles
#

use XML::Filter::Sort::BufferMgr;

ok(1, 'XML::Filter::Sort::BufferMgr compiled OK');


##############################################################################
# Try creating a BufferMgr object
#

my $bm = XML::Filter::Sort::BufferMgr->new(
  Keys => [
            [ '.', 'a', 'a' ]  # All text alpha ascending
	  ]
);

ok(ref($bm), 'Created a buffer manager object');
isa_ok($bm, 'XML::Filter::Sort::BufferMgr');


##############################################################################
# Use it to create a Buffer object
#

my $buffer = $bm->new_buffer();

ok(ref($buffer), 'Created a buffer object');
isa_ok($buffer, 'XML::Filter::Sort::Buffer');


##############################################################################
# Poke some SAX events into the Buffer, close it and confirm that the 
# BufferMgr got the correct sort key value out and stored the Buffer in the
# expected place.
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

$bm->close_buffer($buffer);

my($keyval) = keys(%{$bm->{records}});
is($keyval, 'text content', 'Sort key value extracted and buffer stored');

is(ref($bm->{records}->{$keyval}), 'ARRAY',
   'Container for single-key records');


##############################################################################
# Ask the BufferMgr to regurgitate its buffers as SAX events to a SAX Writer
# handler and confirm the results.
#

my $xmlout = '';
my $writer = XML::SAX::Writer->new(Output => \$xmlout);
$writer->start_document();
$bm->to_sax($writer);
$writer->end_document();
is($xmlout, '<record>text content</record>',
   'XML returned OK from single-level buffer'
);


##############################################################################
# Create a new BufferMgr object to handle multiple (2) sort keys.  Get a
# Buffer, poke some SAX events into it; confirm the sort key values were
# extracted correctly and the storage of the buffer uses a layer of indirection
# for the second key value.
#

$bm = XML::Filter::Sort::BufferMgr->new(
  Keys => [
            [ './@height', 'n', 'a' ], # primary sort key
            [ './@width',  'n', 'a' ], # secondary sort key
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

$buffer = $bm->new_buffer();

$buffer->characters({ Data => '  '});
$buffer->start_element($rec_elem);
$buffer->characters({ Data => 'text content'});
$buffer->end_element($rec_elem);

$bm->close_buffer($buffer);

my($pkeyval) = keys(%{$bm->{records}});
is($pkeyval, 768, 'Primary sort key value extracted and buffer stored');

is(ref($bm->{records}->{$pkeyval}), 'XML::Filter::Sort::BufferMgr',
   'High level container for multi-key records');


my($skeyval) = keys(%{$bm->{records}->{$pkeyval}->{records}});
is($skeyval, 1024, 'Secondary sort key value extracted and buffer stored');

is(ref($bm->{records}->{$pkeyval}->{records}->{$skeyval}), 'ARRAY',
   'Lowest level container for multi-key records');


##############################################################################
# Get the buffer contents back via a SAX Writer and confirm they are as
# expected.
#

$xmlout = '';
$writer = XML::SAX::Writer->new(Output => \$xmlout);
$writer->start_document();
$bm->to_sax($writer);
$writer->end_document();
$xmlout =~ s/"/'/sg;
like($xmlout,
     qr{^  <record(\s+width='1024'|\sheight='768'){2}>text content</record>},
     'XML returned OK from multi-level buffer'
);


