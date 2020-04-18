# Unit tests for WARC::Record::FromVolume module		# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests => 7 + 12 + 19 + 4 + 2;

BEGIN { use_ok('WARC::Record::FromVolume')
	  or BAIL_OUT "WARC::Record::FromVolume failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record::FromVolume v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Record::FromVolume version check')
}

isa_ok('WARC::Record::FromVolume', 'WARC::Record');

{
  my $fail = 0;
  eval {new WARC::Record::FromVolume (); $fail = 1;};
  ok($fail == 0 && $@ =~ m/records are read from volumes/,
     'WARC::Record::FromVolume::new croaks');

  $fail = 0;
  eval {WARC::Record::FromVolume::_read (); $fail = 1;};
  ok($fail == 0 && $@ =~ m/class method/);

  $fail = 0;
  eval {_read WARC::Record::FromVolume (); $fail = 1;};
  ok($fail == 0 && $@ =~ m/undefined volume/,
     'WARC::Record::FromVolume::_read requires a volume parameter');

  $fail = 0;
  eval {_read WARC::Record::FromVolume (1); $fail = 1;};
  ok($fail == 0 && $@ =~ m/undefined offset/,
     'WARC::Record::FromVolume::_read requires an offset value');
}

use File::Spec;
use Scalar::Util qw/refaddr/;

BAIL_OUT 'sample WARC file not found'
  unless -f File::Spec->catfile($Bin, 'test-file-1.warc');
BAIL_OUT 'sample compressed WARC file not found'
  unless -f File::Spec->catfile($Bin, 'test-file-1.warc.gz');

require WARC::Volume;

my %Volume = ();	# map:  tag => volume file name
my %Index = ();		# map:  tag => map:  record ID => offset
$Volume{raw}  = File::Spec->catfile($Bin, 'test-file-1.warc');
$Volume{gz}   = File::Spec->catfile($Bin, 'test-file-1.warc.gz');
$Volume{xhgz} = File::Spec->catfile($Bin, 'test-file-1.xh.warc.gz');
$Volume{esl}  = File::Spec->catfile($Bin, 'test-file-1.esl.warc.gz');
$Volume{vsl}  = File::Spec->catfile($Bin, 'test-file-1.vsl.warc.gz');
$Volume{bsl1} = File::Spec->catfile($Bin, 'test-file-1.b1sl.warc.gz');
$Volume{bsl2} = File::Spec->catfile($Bin, 'test-file-1.b2sl.warc.gz');
$Volume{bsl3} = File::Spec->catfile($Bin, 'test-file-1.b3sl.warc.gz');
$Volume{bsl4} = File::Spec->catfile($Bin, 'test-file-1.b4sl.warc.gz');

my @Z_Variants_Good = qw/xhgz esl vsl bsl3 bsl4/;
my @Z_Variants_Bad = qw/bsl1 bsl2/;
my @Z_Variants = (@Z_Variants_Good, @Z_Variants_Bad);

note('*' x 60);

# Basic tests
sub run_basic_tests ($) {
  my $tag = shift;
  my $volume = mount WARC::Volume ($Volume{$tag});

  plan tests => 4*9 + 1;

  my $record = $volume->first_record;
  isa_ok($record, 'WARC::Record',	'record from file');
  note($record->_dbg_dump);
  is($record->volume, $volume,		'record 0 volume backlink');
  is($record->protocol, 'WARC/1.0',	'record 0 protocol version');
  is($record->fields->{WARC_Type}, 'warcinfo',
					'record 0 type is "warcinfo"');
  is($record->fields->{WARC_Record_ID}, '<urn:test:file-1:record-0>',
					'record 0 ID');
  my $offset = $record->offset;
  is($offset, 0,			'first record at offset 0');
  $Index{$tag}{$record->fields->{WARC_Record_ID}} = $record->offset;
  is($record->logical, $record,		'record 0 is its own logical record');
  is_deeply([$record->segments], [$record],
					'... and is its own only segment');
  is(scalar $record->segments, 1,	'... with segment count of 1');

  $record = $record->next;
  isa_ok($record, 'WARC::Record',	'record from file');
  note($record->_dbg_dump);
  is($record->volume, $volume,		'record 1 volume backlink');
  is($record->protocol, 'WARC/1.0',	'record 1 protocol version');
  is($record->field('WARC-Type'), 'resource',
					'record 1 type is "resource"');
  is($record->field('WARC-Record-ID'), '<urn:test:file-1:record-1>',
					'record 1 ID');
  cmp_ok($offset, '<', $record->offset,	'record 1 at higher offset');
  $offset = $record->offset;
  $Index{$tag}{$record->field('WARC-Record-ID')} = $record->offset;
  is($record->logical, $record,		'record 1 is its own logical record');
  is_deeply([$record->segments], [$record],
					'... and is its own only segment');
  is(scalar $record->segments, 1,	'... with segment count of 1');

  $record = $record->next;
  isa_ok($record, 'WARC::Record',	'record from file');
  note($record->_dbg_dump);
  is($record->volume, $volume,		'record 2 volume backlink');
  is($record->protocol, 'WARC/1.0',	'record 2 protocol version');
  is($record->type, 'resource',		'record 2 type is "resource"');
  is($record->id, '<urn:test:file-1:record-2>',
					'record 2 ID');
  cmp_ok($offset, '<', $record->offset,	'record 2 at higher offset');
  $offset = $record->offset;
  $Index{$tag}{$record->id} = $record->offset;
  is($record->logical, $record,		'record 2 is its own logical record');
  is_deeply([$record->segments], [$record],
					'... and is its own only segment');
  is(scalar $record->segments, 1,	'... with segment count of 1');

  $record = $record->next;
  isa_ok($record, 'WARC::Record',	'record from file');
  note($record->_dbg_dump);
  is($record->volume, $volume,		'record N volume backlink');
  is($record->protocol, 'WARC/1.0',	'record N protocol version');
  is($record->type, 'metadata',		'record N type is "metadata"');
  is($record->id, '<urn:test:file-1:record-N>',
					'record N ID');
  cmp_ok($offset, '<', $record->offset,	'record N at higher offset');
  $offset = $record->offset;
  $Index{$tag}{$record->id} = $record->offset;
  is($record->logical, $record,		'record N is its own logical record');
  is_deeply([$record->segments], [$record],
					'... and is its own only segment');
  is(scalar $record->segments, 1,	'... with segment count of 1');

  ok((not defined $record->next),	'no record after N');
}

{
  subtest "basic tests with uncompressed WARC file"
    => sub { run_basic_tests  'raw' };
  subtest "basic tests with compressed WARC file"
    => sub { run_basic_tests   'gz' };

  subtest "basic tests with variant compressed WARC files (valid)" => sub {
    plan tests => scalar @Z_Variants_Good;
    foreach my $tag (@Z_Variants_Good)
      { subtest "basic tests with compressed WARC file ($tag)"
	  => sub { run_basic_tests $tag } }
  };

  subtest "basic tests with variant compressed WARC files (invalid)" => sub {
    plan tests => 2 * scalar @Z_Variants_Bad;

    my $warnings = 0;
    local $SIG{__WARN__} =
      sub { $warnings++ if $_[0] =~ m/found to be invalid/ };
    foreach my $tag (@Z_Variants_Bad) {
      subtest "basic tests with compressed WARC file ($tag)"
	  => sub { run_basic_tests $tag };
      cmp_ok($warnings, '>', 0,	'invalid variant produces access warnings');
    }
  };

  subtest "sample WARC files contain same records" => sub {
    plan tests => 1 + scalar @Z_Variants;
    foreach my $tag ('gz', @Z_Variants)
      { is_deeply([sort keys %{$Index{$tag}}], [sort keys %{$Index{raw}}],
		  "sample WARC files contain same records (raw/$tag)") }
  };

  {
    my $volume = mount WARC::Volume ($Volume{raw});
    my $z_volume = mount WARC::Volume ($Volume{gz});

    my $fail = 0;
    eval {$volume->record_at(4); $fail = 1;}; # cannot be valid
    ok($fail == 0 && $@ =~ m/record header not found/,
       'reject request for record at bogus offset (raw)');

    $fail = 0;
    eval {$z_volume->record_at(4); $fail = 1;}; # cannot be valid
    ok($fail == 0 && $@ =~ m/record header not found/,
       'reject request for record at bogus offset (gz)');

    my $record = $volume->first_record;
    is($record->block, undef,
       'record from volume returns undef from "block" method');

    $fail = 0;
    eval {$record->block('bogus'); $fail = 1;};
    ok($fail == 0 && $@ =~ m/attempt to set block/,
       'reject attempt to set block on record from volume');

    # following tests for code coverage:
    like($record->_get_compression_error, qr/not compressed/,
	 'no compression error on uncompressed record');

    $record = $z_volume->first_record;
    is($record->_get_compression_error, '',
       'no compression error on valid input');

    # break the object to cover the last branch
    $record->{compression} = 'BOGUS';
    $fail = 0;
    eval {$record->_get_compression_error; $fail = 1;};
    ok($fail == 0 && $@ =~ m/unknown compression/,
       'reject reading compression error for unknown method');
  }
}

note('*' x 60);

# Comparison tests
{
  my $v1 = mount WARC::Volume ($Volume{raw});
  my $v2 = mount WARC::Volume ($Volume{gz});

  my $r0 = new WARC::Record (type => 'metadata');
  my $r1_1 = $v1->record_at($Index{raw}{'<urn:test:file-1:record-1>'});
  my $r1_2 = $v1->record_at($Index{raw}{'<urn:test:file-1:record-2>'});

  my $r1_1b = $v1->record_at($Index{raw}{'<urn:test:file-1:record-1>'});

  cmp_ok($r1_1, '==', $r1_1,	'record equal to itself');
  cmp_ok($r1_1, '==', $r1_1b,	'record equal to other copy of same');
  cmp_ok(refaddr $r1_1, '!=', refaddr $r1_1b,
				'... but other copy is a different object');

  cmp_ok($r0, '<', $r1_1,	'sort new record ahead of disk record');
  cmp_ok($r1_2, '>', $r0,	'sort disk record after new record');

  cmp_ok($r1_1->compareTo($r0), '>', 0,
				'new record less than disk record');
  cmp_ok($r1_1->compareTo($r0, 1), '<', 0,
				'new record less than disk record (argswap)');

  cmp_ok($r1_1->offset, '<', $r1_2->offset,
				'record offsets in order as expected');
  is($r1_1->volume, $r1_2->volume,
				'records from same volume');
  cmp_ok($r1_1, '<', $r1_2,	'records sort by offset within volume');

  my $r2_1 = $v2->record_at($Index{gz}{'<urn:test:file-1:record-1>'});
  my $r2_2 = $v2->record_at($Index{gz}{'<urn:test:file-1:record-2>'});

  cmp_ok($r2_1, '<', $r2_2,	'records from other volume in same order');

  cmp_ok($r1_1->volume->filename, 'lt', $r2_1->volume->filename,
				'volume filenames ordered as expected');

  cmp_ok($r1_1, '<', $r2_1,	'records from two volumes sort by volume');
  cmp_ok($r1_2, '<', $r2_1,	'... and not by offset');
  cmp_ok($r1_2->offset, '>', $r2_1->offset,
				'confirm offsets as expected');

  cmp_ok($r1_2->compareTo($r2_1), '<', 0,
				'records sort by volume');
  cmp_ok($r1_2->compareTo($r2_1, 1), '>', 0,
				'records sort by volume (argswap)');

 SKIP:
  {
    unlink $Volume{raw}.'.shadow' if -e $Volume{raw}.'.shadow';
    skip "failed to create link", 2
      unless eval { link $Volume{raw}, $Volume{raw}.'.shadow' };

    my $v1b = mount WARC::Volume ($Volume{raw}.'.shadow');
    my $r1b_1 = $v1b->record_at($Index{raw}{'<urn:test:file-1:record-1>'});

    cmp_ok($r1_1->volume->filename, 'ne', $r1b_1->volume->filename,
				'main and shadow volumes appear different');
    cmp_ok($r1_1, '==', $r1b_1,	'same record in both is equal');

    unlink $Volume{raw}.'.shadow';
  }
}

note('*' x 60);

# Read record data
{
  my $volume = mount WARC::Volume ($Volume{raw});

  my $xh = $volume->first_record->next->open_block;

  is(scalar <$xh>, "Test item one\n",	'expected data from record block');
  ok((eof $xh),				'block now at eof');

  $xh = $volume->first_record->next->open_continued;

  is(scalar <$xh>, "Test item one\n",
     'expected data from "continued" record block');
  ok((eof $xh),				'"continued" block now at eof');
}

note('*' x 60);

# Replay tests
{
  WARC::Record::Replay::register { $_->id eq '<urn:test:file-1:record-2>' }
      sub { return 'record 2' };
  WARC::Record::Replay::register { 1 } sub { return undef }; # for coverage

  my $volume = mount WARC::Volume ($Volume{raw});

  my $r1 = $volume->record_at($Index{raw}{'<urn:test:file-1:record-1>'});
  my $r2 = $volume->record_at($Index{raw}{'<urn:test:file-1:record-2>'});

  my $o1 = $r1->replay;
  ok((not defined $o1),
     '"replay" method returns undef for unhandled record');
  my $o2 = $r2->replay;
  is($o2, 'record 2',
     '"replay" method invokes mock handler');
}
