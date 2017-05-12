# $Id: 5_diskbuffer.t,v 1.1.1.1 2002/06/14 20:39:57 grantm Exp $

use strict;
use Test::More;
use File::Spec;

BEGIN { # Seems to be required by older Perls

  unless(eval { require Storable }) {
    plan skip_all => 'Storable not installed';
  }

  unless(eval { require XML::SAX::Writer }) {
    plan skip_all => 'XML::SAX::Writer not installed';
  }

  unless(eval { require XML::SAX::ParserFactory }) {
    plan skip_all => 'XML::SAX::ParserFactory not installed';
  }

  unless(eval { require XML::SAX::Machines }) {
    plan skip_all => 'XML::SAX::Machines not installed';
  }

}

plan tests => 25;

use XML::Filter::Sort;
use XML::SAX::ParserFactory;
use XML::SAX::Machines qw( :all );

$^W = 1;

my($xmlin, $xmlout, $sorter);


##############################################################################
# Confirm that the modules compile OK
#

use XML::Filter::Sort::DiskBuffer;
ok(1, 'XML::Filter::Sort::DiskBuffer compiled OK');

use XML::Filter::Sort::DiskBufferMgr;
ok(1, 'XML::Filter::Sort::DiskBufferMgr compiled OK');


##############################################################################
# Try freezing a buffer
#

$xmlin = q(
  <person age='37'>
    <firstname>Zebedee</firstname>
    <lastname>Boozle</lastname>
  </person>);

my $buffer = XML::Filter::Sort::DiskBuffer->new(
  Keys => [ [ 'lastname' ], [ 'firstname' ], [ '@age' ] ]
);
is(ref($buffer), 'XML::Filter::Sort::DiskBuffer',
   'Successfully created a XML::Filter::Sort::DiskBuffer object');

my $parser = XML::SAX::ParserFactory->parser(Handler => $buffer);

$buffer->characters({ Data => "\n  " });
$parser->parse_string($xmlin);
my @keys = $buffer->close();

my $expected_keys = [ qw(Boozle Zebedee 37) ];
is_deeply(\@keys, $expected_keys, 'Inherited keys functionality OK');

my $icicle = $buffer->freeze(undef, @keys);

my $data = Storable::thaw($icicle);

is_deeply($data->[0], $expected_keys, 'Frozen keys manually thawed out OK');


##############################################################################
# Now try thawing it out
#

my $new_buffer = XML::Filter::Sort::DiskBuffer->thaw($icicle);
is(ref($new_buffer), 'XML::Filter::Sort::DiskBuffer',
   'Disk buffer thaw() constructor OK');

isnt($new_buffer, $buffer, 'New buffer is deep copy');

@keys = $new_buffer->key_values();
is_deeply(\@keys, $expected_keys, 'Key values successfully retrieved');

$xmlout = '';
my $writer = XML::SAX::Writer->new(Output => \$xmlout);
$writer->start_document();
$new_buffer->to_sax($writer);
$writer->end_document();
fix_xml($xmlout);

is($xmlout, $xmlin,
   'Original XML reconstructed successfully from thawed buffer');

##############################################################################
# Try re-freezing the thawed buffer and then try thawing it out
#

$icicle = $new_buffer->freeze();

my $newer_buffer = XML::Filter::Sort::DiskBuffer->thaw($icicle);
is(ref($newer_buffer), 'XML::Filter::Sort::DiskBuffer',
   'Re-thawed re-frozen buffer re-constructed OK');

isnt($newer_buffer, $new_buffer, 'New buffer is deep copy');

@keys = $newer_buffer->key_values();
is_deeply(\@keys, $expected_keys, 'Key values successfully retrieved');

$xmlout = '';
$writer = XML::SAX::Writer->new(Output => \$xmlout);
$writer->start_document();
$newer_buffer->to_sax($writer);
$writer->end_document();
fix_xml($xmlout);

is($xmlout, $xmlin,
   'Original XML reconstructed successfully from re-thawed buffer');


##############################################################################
# Now try creating a disk buffer manager object - confirm it fails if no
# temp directory is specified
#

my %opts = (
  Keys => [ ['firstname', 'alpha', 'asc'] ],
);

my $buffer_mgr = eval {
  XML::Filter::Sort::DiskBufferMgr->new(%opts);
};

ok($@, 'Failed to create XML::Filter::Sort::DiskBufferMgr object...');
ok($@ =~ /You must set the 'TempDir' option/i, '... as expected');


##############################################################################
# Create temp directory then try again
#

my $temp_dir = File::Spec->catfile('t', 'temp');
unless(-d $temp_dir) {
  mkdir($temp_dir, 0777);
}
ok(-d $temp_dir, 'Temporary directory exists');

$opts{TempDir} = $temp_dir;
$buffer_mgr = XML::Filter::Sort::DiskBufferMgr->new(%opts);

is(ref($buffer_mgr), 'XML::Filter::Sort::DiskBufferMgr',
   'Successfully created a XML::Filter::Sort::DiskBufferMgr object');


##############################################################################
# Try creating a slave buffer manager
#

my $slave = eval { $buffer_mgr->new() };
ok(!$@, 'Successfully created a slave buffer manager');

is(ref($slave), 'XML::Filter::Sort::DiskBufferMgr',
   'Slave is a XML::Filter::Sort::DiskBufferMgr too');

$slave = undef; # discard it


##############################################################################
# Now feed some data into the disk buffer manager and confirm it gets
# written to disk.
#

my @rec = (
q(<person age='35'>
  <firstname>Zebedee</firstname>
  <lastname>Boozle</lastname>
</person>),

q(<person age='4'>
  <firstname>Yorick</firstname>
  <lastname>Cabbage</lastname>
</person>),

q(<person age='39'>
  <firstname>Yorick</firstname>
  <lastname>Cabbage</lastname>
</person>),

q(<person age='19'>
  <firstname>Xavier</firstname>
  <lastname>Aardvark</lastname>
</person>),
);

store_records($buffer_mgr, @rec);
my $byte_count = $buffer_mgr->{buffered_bytes};

$buffer_mgr->save_to_disk();
my $buffer_dir = $buffer_mgr->{_temp_dir};
ok(-d $buffer_mgr->{_temp_dir}, "Temp directory was created ($buffer_dir)");

my $temp_file = File::Spec->catfile($buffer_dir, '0');
ok(-f $temp_file, "Temp file was created ($temp_file)");

my $file_size = (-s $temp_file);
is(4 * @rec + $byte_count, $file_size, 
   "Disk file size is plausible ($file_size)");


##############################################################################
# Generate SAX events from disk buffer and confirm output.

my $elem = { 
  Name         => 'list',
  LocalName    => 'list',
  Prefix       => '',
  NamespaceURI => '',
  Attributes   => {},
};

$xmlout = '';
$writer = XML::SAX::Writer->new(Output => \$xmlout);
$writer->start_document();
$writer->start_element($elem);
$buffer_mgr->to_sax($writer);
$writer->end_element($elem);
$writer->end_document();
fix_xml($xmlout);

is($xmlout, "<list>$rec[3]$rec[1]$rec[2]$rec[0]</list>", 
   'XML from disk buffer looks good');

ok(!-f $temp_file, 'Temp file was deleted');

$buffer_mgr = undef;  # destroy buffer manager object
ok(!-d $buffer_dir, 'Temp directory was deleted');

exit;



##############################################################################
#                       S U B R O U T I N E S
##############################################################################

##############################################################################
# Sometimes the output from the SAX pipeline may not be exactly what we're
# expecting - for benign reasons.  This routine strips the initial XML
# declaration which gets added by LibXML but not by other parsers.  It also
# changes attribute double quotes to single.
#

sub fix_xml {
  $_[0] =~ s{^<\?xml\s.*?\?>\s*}{}s;
  $_[0] =~ s{(\w+)="([^>]*?)"}{$1='$2'}sg;
}


##############################################################################
# Takes a buffer and a list of well formed XML 'records'.  Takes each record,
# parses it to a buffer and stores it.
#

sub store_records{
  my $buffer_mgr = shift;

  foreach my $rec (@_) {
    my $buffer = $buffer_mgr->new_buffer();
    XML::SAX::ParserFactory->parser(Handler => $buffer)->parse_string($rec);
    $buffer_mgr->close_buffer($buffer);
  }

}
