# Unit tests for WARC::Index::File::CDX module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests
  => 4	# loading tests
  +  6	# reject bogus/insufficient indexes
  + 14	# read via minimal index
  +  8	# read gz via minimal index
  +  8	# read gz via minimal index with both offset columns
  + 24	# search via URL-only index
  + 17	# search via timestamp-only index
  + 12	# search via ID-only index
  +  4;	# monkeywrench tests for coverage

BEGIN { use_ok('WARC::Index::File::CDX')
	  or BAIL_OUT "WARC::Index::File::CDX failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Index::File::CDX v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Index::File::CDX version check')
}

isa_ok('WARC::Index::File::CDX', 'WARC::Index', 'WARC::Index::File::CDX');

is(WARC::Index::find_handler('test.cdx'), 'WARC::Index::File::CDX',
   'register CDX index support');

use Errno qw/ENOENT/;
use File::Spec;

require WARC::Date;

# Note that all of these are atypical usage, since test-file-1.warc
#  contains only warcinfo, resource, and metadata records.

my %Sample_Indexes =
  ( bogus_empty		=> 'test-file-1.bogus-empty.cdx',
    bogus_no_header	=> 'test-file-1.bogus-no-header.cdx',
    bogus_bad_tag	=> 'test-file-1.bogus-bad-tag.cdx',
    bogus_bad_header	=> 'test-file-1.bogus-bad-header.cdx',
    bogus_no_offset	=> 'test-file-1.bogus-no-Vv.cdx',
    bogus_no_volume	=> 'test-file-1.bogus-no-g.cdx',

    minimal_useless	=> 'test-file-1.minimal-gv.cdx',
    minimal_gz_useless	=> 'test-file-1.minimalgz-gV.cdx',
    minimal_gzv_useless	=> 'test-file-1.minimalgz-gvV.cdx',

    search_by_url	=> 'test-file-1.searchgz-agV.cdx',
    search_by_time	=> 'test-file-1.searchgz-bgV.cdx',
    search_by_record_id	=> 'test-file-1.searchgz-ugV.cdx',
  );

foreach my $file (values %Sample_Indexes)
  { BAIL_OUT "sample CDX file '$file' not found"
      unless -f File::Spec->catfile($Bin, $file) }

my %Volume = ();	# map:  tag => volume file name
my %Index = ();		# map:  tag => map:  record ID => offset
$Volume{raw}  = File::Spec->catfile($Bin, 'test-file-1.warc');
$Volume{gz}   = File::Spec->catfile($Bin, 'test-file-1.warc.gz');

note('*' x 60);

# Basic tests with bogus and/or insufficient indexes
{
  my $index;

  BAIL_OUT "what do you mean 'test-file-1.bogus-does-not-exist.cdx' exists?"
    if -f File::Spec->catfile($Bin, 'test-file-1.bogus-does-not-exist.cdx');

  {
    my $ENOENT_message = '';
    { local $! = ENOENT; $ENOENT_message = "$!" }

    BAIL_OUT "could not get message for ENOENT" unless $ENOENT_message;

    my $fail = 0;
    eval {$index = attach WARC::Index::File::CDX
	    File::Spec->catfile($Bin, 'test-file-1.bogus-does-not-exist.cdx');
	  $fail = 1};
    ok($fail == 0 && $@ =~ m/$ENOENT_message/,
       'reject index from nonexistent file');
  }

  my $fail = 0;
  eval {$index = attach WARC::Index::File::CDX
	  File::Spec->catfile($Bin, $Sample_Indexes{bogus_empty});
	$fail = 1};
  ok($fail == 0 && $@ =~ m/could not read CDX header/,
     'reject index from empty file');

  $fail = 0;
  eval {$index = attach WARC::Index::File::CDX
	  File::Spec->catfile($Bin, $Sample_Indexes{bogus_bad_tag});
	$fail = 1};
  ok($fail == 0 && $@ =~ m/no CDX marker found/,
     'reject index with bad "CDX" tag');

  $fail = 0;
  eval {$index = attach WARC::Index::File::CDX
	  File::Spec->catfile($Bin, $Sample_Indexes{bogus_bad_header});
	$fail = 1};
  ok($fail == 0 && $@ =~ m/no CDX marker found/,
     'reject index with bad header after "CDX" tag');

  $fail = 0;
  eval {$index = attach WARC::Index::File::CDX
	  File::Spec->catfile($Bin, $Sample_Indexes{bogus_no_offset});
	$fail = 1};
  ok($fail == 0 && $@ =~ m/does not index record offset/,
     'reject index without record offsets');

  $fail = 0;
  eval {$index = attach WARC::Index::File::CDX
	  File::Spec->catfile($Bin, $Sample_Indexes{bogus_no_volume});
	$fail = 1};
  ok($fail == 0 && $@ =~ m/does not index WARC file name/,
     'reject index without WARC file names');
}

note('*' x 60);

# Basic tests with minimal index
{
  my $index = attach WARC::Index::File::CDX
    File::Spec->catfile($Bin, $Sample_Indexes{minimal_useless});
  note($index->_dbg_dump);

  my $entry = $index->first_entry;

  is($entry->record->id, '<urn:test:file-1:record-0>',
     'record 0 readable via index with expected ID');
  $entry = $entry->next;
  ok((defined $entry),		'record 0 next');

  is($entry->record->id, '<urn:test:file-1:record-1>',
     'record 1 readable via index with expected ID');
  $entry = $entry->next;
  ok((defined $entry),		'record 1 next');

  is($entry->record->id, '<urn:test:file-1:record-2>',
     'record 2 readable via index with expected ID');
  $entry = $entry->next;
  ok((defined $entry),		'record 2 next');

  is($entry->record->id, '<urn:test:file-1:record-N>',
     'record N readable via index with expected ID');
  $entry = $entry->next;
  ok((not defined $entry),	'record N is last');

  {
    my $fail = 0;
    eval {$entry = $index->entry_at(3); $fail = 1;};
    ok($fail == 0 && $@ =~ m/not a record boundary/,
       'reject request for bogus index entry (1)');

    $fail = 0;
    eval {$entry = $index->entry_at(0); $fail = 1;};
    ok($fail == 0 && $@ =~ m/seek/,
       'reject request for bogus index entry (2)');
  }

  ok((not $index->searchable($_)),	"minimal index cannot search by $_")
    for qw/url url_prefix time record_id/;
}

note('*' x 60);

# Basic tests with minimal index on compressed WARC file
{
  my $index = attach WARC::Index::File::CDX
    File::Spec->catfile($Bin, $Sample_Indexes{minimal_gz_useless});
  note($index->_dbg_dump);

  my $entry = $index->first_entry;

  is($entry->record->id, '<urn:test:file-1:record-0>',
     'record 0 readable via index with expected ID');
  $entry = $entry->next;
  ok((defined $entry),		'record 0 next');

  is($entry->record->id, '<urn:test:file-1:record-1>',
     'record 1 readable via index with expected ID');
  $entry = $entry->next;
  ok((defined $entry),		'record 1 next');

  is($entry->record->id, '<urn:test:file-1:record-2>',
     'record 2 readable via index with expected ID');
  $entry = $entry->next;
  ok((defined $entry),		'record 2 next');

  is($entry->record->id, '<urn:test:file-1:record-N>',
     'record N readable via index with expected ID');
  $entry = $entry->next;
  ok((not defined $entry),	'record N is last');
}

note('*' x 60);

# Basic tests with both offset columns on compressed WARC file
{
  my $index = attach WARC::Index::File::CDX
    File::Spec->catfile($Bin, $Sample_Indexes{minimal_gzv_useless});
  note($index->_dbg_dump);

  my $entry = $index->first_entry;

  is($entry->record->id, '<urn:test:file-1:record-0>',
     'record 0 readable via index with expected ID');
  $entry = $entry->next;
  ok((defined $entry),		'record 0 next');

  is($entry->record->id, '<urn:test:file-1:record-1>',
     'record 1 readable via index with expected ID');
  $entry = $entry->next;
  ok((defined $entry),		'record 1 next');

  is($entry->record->id, '<urn:test:file-1:record-2>',
     'record 2 readable via index with expected ID');
  $entry = $entry->next;
  ok((defined $entry),		'record 2 next');

  is($entry->record->id, '<urn:test:file-1:record-N>',
     'record N readable via index with expected ID');
  $entry = $entry->next;
  ok((not defined $entry),	'record N is last');
}

note('*' x 60);

# Search tests with URL-only index
{
  my $index = attach WARC::Index::File::CDX
    File::Spec->catfile($Bin, $Sample_Indexes{search_by_url});
  note($index->_dbg_dump);

  ok(($index->searchable('url')),	'URL index can search by url');
  ok(($index->searchable('url_prefix')),'URL index can search by url_prefix');
  ok((not $index->searchable('time')),	'URL index cannot search by time');
  ok((not $index->searchable('record_id')),
					'URL index cannot search by record_id');

  my $result; my @results;

  @results = $index->search(url => 'http://warc.test/foo/record-0');
  $result = $index->search(url => 'http://warc.test/foo/record-0');
  is(scalar @results, 1,	'unique URL for record 0 returns one entry');
  is($results[0]->record->id, '<urn:test:file-1:record-0>',
				'... and that entry is record 0');
  is($result->record->id, '<urn:test:file-1:record-0>',
				'... also record 0 in scalar context');

  @results = $index->search(url => 'http://warc.test/bar/record-1');
  $result = $index->search(url => 'http://warc.test/bar/record-1');
  is(scalar @results, 1,	'unique URL for record 1 returns one entry');
  is($results[0]->record->id, '<urn:test:file-1:record-1>',
				'... and that entry is record 1');
  is($result->record->id, '<urn:test:file-1:record-1>',
				'... also record 1 in scalar context');

  @results = $index->search(url => 'http://warc.test/bar/record-2');
  $result = $index->search(url => 'http://warc.test/bar/record-2');
  is(scalar @results, 1,	'unique URL for record 2 returns one entry');
  is($results[0]->record->id, '<urn:test:file-1:record-2>',
				'... and that entry is record 2');
  is($result->record->id, '<urn:test:file-1:record-2>',
				'... also record 2 in scalar context');

  @results = $index->search(url => 'http://warc.test/baz/record-N');
  $result = $index->search(url => 'http://warc.test/baz/record-N');
  is(scalar @results, 1,	'unique URL for record N returns one entry');
  is($results[0]->record->id, '<urn:test:file-1:record-N>',
				'... and that entry is record N');
  is($result->record->id, '<urn:test:file-1:record-N>',
				'... also record N in scalar context');

  @results = $index->search(url_prefix => 'http://warc.test/foo/');
  is(scalar @results, 1,	'prefix "/foo/" returns one entry');
  is($results[0]->record->id, '<urn:test:file-1:record-0>',
				'... and that entry is record 0');

  @results = $index->search(url_prefix => 'http://warc.test/bar/');
  is(scalar @results, 2,	'prefix "/bar/" returns two entries');
  is_deeply([sort map {$_->record->id} @results],
	    ['<urn:test:file-1:record-1>', '<urn:test:file-1:record-2>'],
				'... and they are records 1 and 2');

  @results = $index->search(time => 1);
  is(scalar @results, 0,	'searching URL index by time returns nothing');
  $result = $index->search(time => 1);
  ok((not defined $result),	'... and the best match by time is undefined');

  @results = $index->search(record_id => 1);
  is(scalar @results, 0,	'searching URL index by ID returns nothing');
  $result = $index->search(record_id => 1);
  ok((not defined $result),	'... and the best match by ID is undefined');
}

note('*' x 60);

# Search tests with timestamp-only index
{
  my $index = attach WARC::Index::File::CDX
    File::Spec->catfile($Bin, $Sample_Indexes{search_by_time});
  note($index->_dbg_dump);

  ok((not $index->searchable('url')),	'time index cannot search by url');
  ok((not $index->searchable('url_prefix')),
     'time index cannot search by url_prefix');
  ok(($index->searchable('time')),	'time index can search by time');
  ok((not $index->searchable('record_id')),
     'time index cannot search by record_id');

  my $when = WARC::Date->from_string('2019-09-02T23:25:57Z');

  {
    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned = 1 if (shift) =~ m/void context/ };
    $index->search(time => $when);
    ok($warned == 1,
       'calling search method in void context produces warning');
  }

  {
    my $fail = 0;
    eval {my $what = $index->search(); $fail = 1;};
    ok($fail == 0 && $@ =~ m/no arguments/,
       'calling search method with no arguments croaks');

    $fail = 0;
    eval {my $what = $index->search('foo'); $fail = 1;};
    ok($fail == 0 && $@ =~ m/odd number of arguments/,
       'calling search method with odd number of arguments croaks');
  }

  my @results = $index->search(time => $when);
  is(scalar @results, 4,	'search by time returns all records');

  my $result = $index->search(time => $when);
  is($result->distance(time => $when), 0,
				'exact match for timestamp found');
  is($result->record->id, '<urn:test:file-1:record-2>',
				'record 2 found by timestamp');

  $when = WARC::Date->from_string('2019-09-02T23:25:54Z');
  $result = $index->search(time => $when);
  cmp_ok($result->distance(time => $when), '>', 0,
				'no exact match for earlier timestamp');
  is($result->record->id, '<urn:test:file-1:record-0>',
				'record 0 was best match');

  $when = WARC::Date->from_string('2019-09-02T23:26:00Z');
  $result = $index->search(time => $when);
  cmp_ok($result->distance(time => $when), '>', 0,
				'no exact match for later timestamp');

  @results = $index->search(url_prefix => 'http://warc.test/');
  is(scalar @results, 0,	'searching time index by URL returns nothing');
  $result = $index->search(url_prefix => 'http://warc.test/');
  ok((not defined $result),	'... and the best match by URL is undefined');

  @results = $index->search(record_id => 1);
  is(scalar @results, 0,	'searching time index by ID returns nothing');
  $result = $index->search(record_id => 1);
  ok((not defined $result),	'... and the best match by ID is undefined');
}

note('*' x 60);

# Search tests with ID-only index
{
  my $index = attach WARC::Index::File::CDX
    File::Spec->catfile($Bin, $Sample_Indexes{search_by_record_id});
  note($index->_dbg_dump);

  ok((not $index->searchable('url')),	'ID index cannot search by url');
  ok((not $index->searchable('url_prefix')),
					'ID index cannot search by url_prefix');
  ok((not $index->searchable('time')),	'ID index cannot search by time');
  ok(($index->searchable('record_id')),
					'ID index can search by record_id');

  foreach my $id (map {"<urn:test:file-1:record-$_>"} qw/0 1 2 N/) {
    my $entry = $index->search(record_id => $id);
    is($entry->record->id, $id,	"search by ID $id returns record");
  }

  my @results = $index->search(url_prefix => 'http://warc.test/');
  is(scalar @results, 0,	'searching ID index by URL returns nothing');
  my $result = $index->search(url_prefix => 'http://warc.test/');
  ok((not defined $result),	'... and the best match by URL is undefined');

  @results = $index->search(time => 1);
  is(scalar @results, 0,	'searching ID index by time returns nothing');
  $result = $index->search(time => 1);
  ok((not defined $result),	'... and the best match by time is undefined');
}

note('*' x 60);

# Monkeywrench tests
{
  my $index = attach WARC::Index::File::CDX
    File::Spec->catfile($Bin, $Sample_Indexes{search_by_url});

  {
    my $does_not_exist = $index->{cdx_file}.'.does-not-exist';
    BAIL_OUT "what do you mean '$does_not_exist' exists?"
      if -f $does_not_exist;
    $index->{cdx_file} = $does_not_exist;
  }

  {
    my $ENOENT_message = '';
    { local $! = ENOENT; $ENOENT_message = "$!" }
    BAIL_OUT "could not get message for ENOENT" unless $ENOENT_message;

    my $fail = 0;
    eval {my $r = $index->search(url => 'foo'); $fail = 1;};
    ok($fail == 0 && $@ =~ m/$ENOENT_message/,
       'croak when file "disappears" between \'attach\' and \'search\'');

    $fail = 0;
    eval {my @r = $index->search(url => 'foo'); $fail = 1;};
    ok($fail == 0 && $@ =~ m/$ENOENT_message/,
       'croak when file "disappears" between \'attach\' and \'search\' (list)');

    $fail = 0;
    eval {my $r = $index->first_entry; $fail = 1;};
    ok($fail == 0 && $@ =~ m/$ENOENT_message/,
       'croak when file "disappears" between \'attach\' and \'first_entry\'');

    $fail = 0;
    eval {my $r = $index->entry_at(4); $fail = 1;};
    ok($fail == 0 && $@ =~ m/$ENOENT_message/,
       'croak when file "disappears" between \'attach\' and \'entry_at\'');
  }
}
