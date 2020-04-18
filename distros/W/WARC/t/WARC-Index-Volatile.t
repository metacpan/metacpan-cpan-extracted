# Unit tests for WARC::Index::Volatile module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests =>
     2	# loading tests
  + 17	# basic tests
  + 10	# incremental index building and multi-column search tests
  +  2	# metaindex tests
  + 14	# WARC::Collection tests
  +  2	# monkeywrench tests
  +  1;	# memory leak check

BEGIN {
  my $have_test_differences = 0;
  eval q{use Test::Differences; unified_diff; $have_test_differences = 1};
  *eq_or_diff = \&is_deeply unless $have_test_differences;
}

BEGIN { use_ok('WARC::Index::Volatile')
	  or BAIL_OUT "WARC::Index::Volatile failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Index::Volatile v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/ version v9999.*required--this is only version/,
     'WARC::Index::Volatile version check')
}

use File::Spec;

my %Volume = ();	# map:	tag => volume file name

$Volume{raw1}	= File::Spec->catfile($Bin, 'test-file-1.warc');
$Volume{raw2}	= File::Spec->catfile($Bin, 'test-file-2.warc');
$Volume{gz1}	= File::Spec->catfile($Bin, 'test-file-1.warc.gz');

require WARC::Collection;
require WARC::Date;

note('*' x 60);

# Basic tests
{
  {
    my $fail = 0;
    eval {my $index = build WARC::Index::Volatile (bogus => 1); $fail = 1};
    ok($fail == 0 && $@ =~ m/unknown option 'bogus' .* volatile index/,
       'reject bogus option building volatile index');

    $fail = 0;
    eval {my $index = build WARC::Index::Volatile (columns => ['bogus']);
	  $fail = 1};
    ok($fail == 0 && $@ =~ m/unknown index column/,
       'reject bogus column building volatile index');
  }

  {
    my $pass = 0; my $warned = 0;
    eval {
      local $SIG{__WARN__} = sub { $warned++ if $_[0] =~ m/void context/ };
      build WARC::Index::Volatile (from => $Volume{raw1});
      $pass = 1;
    };
    ok($pass && $warned,'warn if building volatile index in void context');
  }

  local @WARC::Index::Volatile::Default_Column_Set = qw(record_id);
  my $index = attach WARC::Index::Volatile ($Volume{raw1}, $Volume{raw2});

  note($index->_dbg_dump);

  ok($index->searchable('record_id'),	'index searchable by record_id');
  ok((not $index->searchable('url')),	'index not searchable by url');

  {
    my $pass = 0; my $warned = 0;
    eval {
      local $SIG{__WARN__} = sub { $warned++ if $_[0] =~ m/void context/ };
      $index->search(record_id => 'bogus'); $pass = 1;
    };
    ok($pass && $warned,'warn if searching index in void context');
  }

  {
    my $fail = 0;
    eval {my $r = $index->search(); $fail = 1};
    ok($fail == 0 && $@ =~ m/no arguments/,
       'reject bogus search with no arguments');

    $fail = 0;
    eval {my $r = $index->search('bogus'); $fail = 1};
    ok($fail == 0 && $@ =~ m/odd number of arguments/,
       'reject bogus search with odd number of arguments');

    $fail = 0;
    eval {my $r = $index->search(url => 1); $fail = 1};
    ok($fail == 0 && $@ =~ m/no usable search key/,
       'reject bogus search with no indexed key');
  }

  subtest 'find entry list by record_id' => sub {
    plan tests => 2;

    my @e = $index->search(record_id => '<urn:test:file-1:record-0>');
    is(scalar @e, 1,				'one record found by id');
    is($e[0]->record->id, '<urn:test:file-1:record-0>',
       'expected record found');
  };

  {
    my $e = $index->search(record_id => '<urn:test:file-1:record-0>');
    is($e->record->id, '<urn:test:file-1:record-0>',
       'expected record found by id');
  }

  {
    my $vol1_count = 0; my $saw_record_N = 0;
    for (my $e = $index->first_entry; $e; $e = $e->next)
      {	$saw_record_N++ if $e->record->id =~ m/:record-N/;
	$vol1_count++ if $e->volume->filename =~ m/test-file-1/ }
    is($vol1_count, 4,	'found 4 entries in test-file-1 volume');
    is($saw_record_N, 2,'found 2 trailing records in 2 test volumes');

    # add duplicate volume
    $index->add(mount WARC::Volume ($Volume{raw1}));

    $vol1_count = 0; $saw_record_N = 0;
    for (my $e = $index->first_entry; $e; $e = $e->next)
      {	$saw_record_N++ if $e->record->id =~ m/:record-N/;
	$vol1_count++ if $e->volume->filename =~ m/test-file-1/ }
    is($vol1_count, 4,	'found 4 entries in test-file-1 volume after dup');
    is($saw_record_N, 2,'found 2 trailing records in 2 test volumes after dup');
  }

  {
    my $e = $index->first_entry;
    is($e->value('record_id'), '<urn:test:file-1:record-0>',
       'first entry maps expected record');
    is($e->value('_volume'), undef,
       'entry object hides internal key');
  }
}

note('*' x 60);

# Incremental index building and multi-column search tests
{
  my $index = build WARC::Index::Volatile (columns => [qw/record_id url/],
					   from => $Volume{gz1});

  note($index->_dbg_dump);

  {
    my $fail = 0;
    eval {$index->add(WARC::Date->now()); $fail = 1};
    ok($fail == 0 && $@ =~ m/unrecognized object/,
       'reject adding bogus object to index');
  }

  $index->add($Volume{raw2}); pass('add other test volume');
  note($index->_dbg_dump);

  {
    my @e = $index->search(url => '*');
    is(scalar @e, 2,	'expected number of entries found in url search');
    is_deeply([sort map {$_->value('record_id')} @e],
	      [sort '<urn:test:file-2:record-3>', '<urn:test:file-2:record-4>'],
	      'expected records returned in initial search');

    @e = $index->search(url => '*', record_id => '<urn:test:file-2:record-4>');
    is(scalar @e, 1,	'unique result when narrowed with record_id');
    is($e[0]->value('record_id'), '<urn:test:file-2:record-4>',
       'expected record found when narrowed by record_id');
  }

  {
    my $e = $index->search
      (url => 'http://example.test/',
       time => WARC::Date->from_string('2019-12-16T23:21:57Z'));
    is($e->value('record_id'), '<urn:test:file-2:record-2>',
       'search by url and date returns expected best match');

    $e = $index->search(url => 'http://example.test/',
			record_id => '<urn:test:file-2:record-6>');
    is($e->value('record_id'), '<urn:test:file-2:record-6>',
       'search by url and record_id returns expected record');

    # for code coverage:
    $index->add($e); $index->add($e->record);
  }

  $index = build WARC::Index::Volatile (from => [$Volume{raw2}],
					columns => [qw/record_id url_prefix/]);

  {
    my @e = $index->search(url_prefix => 'http://example.test');

    is(scalar @e, 20,	'expected number of entries found in url_prefix search');
    eq_or_diff([sort map $_->value('url'), @e],
	       [sort
		(('http://example.test/') x 8, ('http://example.test/1') x 2,
		 (map 'http://example.test/r'.$_, 1..5) x 2)],
	       'expected records returned from url_prefix search');
  }
}

note('*' x 60);

# Metaindex as index cache
{
  my $index1 = attach WARC::Index::Volatile ($Volume{raw2});
  my $index2 = attach WARC::Index::Volatile ($index1);

  subtest 'copy index' => sub {
    my $record_count = 0;
    { my $vol = mount WARC::Volume ($Volume{raw2});
      for (my $rec = $vol->first_record; $rec; $rec = $rec->next)
	{ $record_count++ } }
    plan tests => $record_count;

    for (my ($e1, $e2) = map $_->first_entry, ($index1, $index2);
	 $e1 && $e2;
	($e1, $e2) = map $_->next, ($e1, $e2))
      { is($e1->value('record_id'), $e2->value('record_id'),
	   'copy index entry '.$e1->value('record_id')) }
  };

  $index2 = build WARC::Index::Volatile (columns => [qw/record_id url/],
					 from => $index1);

  subtest 'copy and reindex' => sub {
    my $record_count = 0;
    { my $vol = mount WARC::Volume ($Volume{raw2});
      for (my $rec = $vol->first_record; $rec; $rec = $rec->next)
	{ $record_count++ } }
    plan tests => 2*$record_count;

    for (my ($e1, $e2) = map $_->first_entry, ($index1, $index2);
	 $e1 && $e2;
	 ($e1, $e2) = map $_->next, ($e1, $e2)) {
      is($e1->value('record_id'), $e2->value('record_id'),
	 'copy index entry '.$e1->value('record_id'));
      is($e1->record->field('WARC-Target-URI'), $e2->value('url'),
	 'add URL to index entry '.$e2->value('record_id'));
    }
  };
}

note('*' x 60);

# WARC::Collection index backend tests
{
  my $collect = assemble WARC::Collection ($Volume{raw1}, $Volume{raw2});

  my @rids = qw/ <urn:test:file-1:record-0> <urn:test:file-2:record-0>
		 <urn:test:file-1:record-1> <urn:test:file-2:record-1>
		 <urn:test:file-1:record-2> <urn:test:file-2:record-2>
		 <urn:test:file-2:record-3> <urn:test:file-2:record-4>
		 <urn:test:file-2:record-5> <urn:test:file-2:record-6>
		 <urn:test:file-2:record-7> <urn:test:file-2:record-8>
		 <urn:test:file-1:record-N> <urn:test:file-2:record-N> /;

  foreach my $rid (@rids)
    { is($collect->search(record_id => $rid)->id, $rid,
	 'collection finds record '.$rid) }
}

note('*' x 60);

# Monkeywrench tests
{
  my $index = build WARC::Index::Volatile
    (from => [$Volume{raw2}], columns => [qw/record_id url_prefix/]);

  my $fail = 0;
  {
    local $WARC::Index::Entry::_distance_value_map{url_prefix}[0] = 'bogus';
    eval {my $e = $index->search(url_prefix => 'bogus'); $fail = 1};
    ok($fail == 0 && $@ =~ m/unimplemented search mode bogus/,
       'reject search on key using unimplemented mode');
  }

  $fail = 0;
  $index->{by}{record_id} = 'bogus!';
  eval {$index->add($Volume{raw1}); $fail = 1};
  ok($fail == 0 && $@ =~ m/unknown .* in record_id index slot/,
     'fail on internal error with bad structure');
}

note('*' x 60);

is($WARC::Index::Volatile::_total_destroyed,
   $WARC::Index::Volatile::_total_constructed,
   'no memory leaks');
