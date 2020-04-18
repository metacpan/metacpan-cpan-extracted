# Unit tests for WARC::Record::Logical module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests =>
     2	# Loading tests
  + 12	# Basic tests with bogus record sets
  + 30	# Basic tests with valid record sets from collection
  +  6	# Basic tests with valid record sets needing heuristics
  +  4	# Large record tests
  +  2;	# Verify construction/destruction balance

BEGIN { $INC{'WARC/Record/Logical/Heuristics.pm'} = 'mocked in test driver' }

BEGIN { use_ok('WARC::Record::Logical')
	  or BAIL_OUT "WARC::Record::Logical failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record::Logical v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/ version v9999.*required--this is only version/,
     'WARC::Record::Logical version check')
}

use Carp;
use Config;
use Math::BigInt;

our @MOCK_Heuristics_FindFirst_Results = (undef);
our @MOCK_Heuristics_FindRest_Results = ();

{
  package WARC::Record::Logical::Heuristics;

  sub find_first_segment { return @MOCK_Heuristics_FindFirst_Results, @_ }
  sub find_continuation  { my $first_segment = shift;
			   return @MOCK_Heuristics_FindRest_Results, @_  }
}

require WARC::Collection;
require WARC::Fields;
require WARC::Index;
require WARC::Index::Entry;
require WARC::Record;

{
  package WARC::Volume::_TestMock;
  use overload '""' => 'filename', fallback => 1;
  sub new { my $class = shift; my $name = shift; bless \$name, $class }
  sub filename { ${(shift)} }
}
{
  package WARC::Record::_TestMock;

  our @ISA = qw(WARC::Record);

  sub DESTROY { our $_total_destroyed;	$_total_destroyed++ }

  sub new {
    my $class = shift;
    my $offset = shift;
    my $collection = shift;

    { our $_total_constructed;	$_total_constructed++ }

    bless { collection => $collection,
	    fields => new WARC::Fields (@_),
	    offset => $offset, volume => 'mock volume' }, $class;
  }

  sub protocol { 'protocol '.(shift)->{offset} }
  sub volume { new WARC::Volume::_TestMock 'volume '.(shift)->{offset} }
  sub offset { (shift)->{offset} }
  sub next { 'next '.(shift)->{offset} }
}
{
  package WARC::Index::Entry::_TestMock;

  our @ISA = qw(WARC::Index::Entry);

  # Each entry holds:
  #  position in array (added when building index)
  #  WARC::Fields object

  use Carp;

  sub tag { return 'mock volume:'.$_[0]->[0] }
  sub record {
    my $self = shift;
    my $collection_key = shift;
    my $collection = shift;

    confess "unexpected call to WARC::Index::Entry::_TestMock::record"
      unless $collection_key eq 'collection';
    new WARC::Record::_TestMock ($self->[0], $collection, %{$self->[1]})
  }
  sub value {
    my $self = shift;
    my $key = shift;

    if ($key eq 'record_id')
      { return $self->[1]->{WARC_Record_ID} }
    elsif ($key eq 'segment_origin_id')
      { return $self->[1]->{WARC_Segment_Origin_ID} }
    else
      { confess "unexpected call to WARC::Index::Entry::_TestMock::value" }
  }
}

{
  package WARC::Index::_TestMock;

  our @ISA = qw(WARC::Index);

  # Each index is an array of its records, as index entries.

  sub attach {
    my $class = shift;

    bless
      [map { bless [$_, new WARC::Fields (@{$_[$_]})],
	       'WARC::Index::Entry::_TestMock' } 0..$#_], $class
  }

  sub searchable {
    my $self = shift;
    my $key = shift;

    return $key eq 'record_id' || $key eq 'segment_origin_id'
  }

  sub search {
    my $self = shift;

    my @res = @$self;
    foreach my $r (@res) {
      next unless defined $r;
      $r = undef unless $r->distance(@_) >= 0;
    }

    @res = grep { defined } @res;
    if (wantarray) { return @res }
    else { return shift @res } # no sort in this test mock
  }
}
{
  package WARC::Index::_TestMock::NoID;

  our @ISA = qw(WARC::Index::_TestMock);

  sub searchable { return $_[1] eq 'segment_origin_id' }
}
{
  package WARC::Index::_TestMock::NoOrigin;

  our @ISA = qw(WARC::Index::_TestMock);

  sub searchable { return $_[1] eq 'record_id' }
}

note('*' x 60);

# Basic tests with bogus record sets
{
  my $warnings = 0; my $warned = 0;
  local $SIG{__WARN__} = sub { $warnings++;
			       if ($_[0] =~ m/failed to locate all/)
				 { $warned = 1 } else { warn $_[0] } };
  my $index = attach WARC::Index::_TestMock
    ([WARC_Type => 'resource', Content_Length => 2400,
      WARC_Record_ID => '<urn:test:record-1>']);
  my $collection = assemble WARC::Collection $index;

  my $record = $collection->search(record_id => '<urn:test:record-1>');

  my $fail = 0;
  eval {_read WARC::Record::Logical $record; $fail = 1;};
  ok($fail == 0 && $@ =~ m/non-segmented record/,
     'loading logical record for non-segmented record croaks')
    or diag($@);

  $index = attach WARC::Index::_TestMock
    ([WARC_Type => 'resource', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 1],
     [WARC_Type => 'continuation', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-2>',
      WARC_Segment_Number => 2]);
  $collection = assemble WARC::Collection $index;

  $record = $collection->search(record_id => '<urn:test:record-1:segment-2>');

  $fail = 0;
  eval {_read WARC::Record::Logical $record; $fail = 1;};
  ok($fail == 0 && $@ =~ m/WARC-Segment-Origin-ID/,
     'loading logical record from bogus member without origin-ID croaks')
    or diag($@);

  $record = $collection->search(record_id => '<urn:test:record-1:segment-1>');

  ($fail, $warnings, $warned) = (0, 0, 0);
  eval {_read WARC::Record::Logical $record; $fail = 1;};
  ok($fail == 0 && $@ =~ m/failed to locate any continuation segments/,
     'loading logical record croaks if no continuation segments found (1)')
    or diag($@);
  ok($warnings == 1 && $warned == 1, 'only expected warning produced');

  $index = attach WARC::Index::_TestMock
    ([WARC_Type => 'resource', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 1],
     [WARC_Type => 'continuation', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-2>',
      WARC_Segment_Origin_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 2]);
  $collection = assemble WARC::Collection $index;

  $record = $collection->search(record_id => '<urn:test:record-1:segment-2>');

  ($fail, $warnings, $warned) = (0, 0, 0);
  eval {_read WARC::Record::Logical $record; $fail = 1;};
  ok($fail == 0 && $@ =~ m/WARC-Segment-Total-Length/,
     'loading logical record with no Total-Length header croaks')
    or diag($@);
  ok($warnings == 1 && $warned == 1, 'only expected warning produced');

  $index = attach WARC::Index::_TestMock::NoID
    ([WARC_Type => 'resource', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 1],
     [WARC_Type => 'continuation', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-2>',
      WARC_Segment_Origin_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 2, WARC_Segment_Total_Length => 2400]);
  $collection = assemble WARC::Collection $index;

  $record = $collection->search(record_id => '<urn:test:record-1:segment-2>');

  $fail = 0;
  eval {_read WARC::Record::Logical $record; $fail = 1;};
  ok($fail == 0 && $@ =~ m/failed to locate first segment/,
     'loading logical record croaks if first segment not found (1)')
    or diag($@);

  $index = attach WARC::Index::_TestMock::NoOrigin
    ([WARC_Type => 'resource', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 1],
     [WARC_Type => 'continuation', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-2>',
      WARC_Segment_Origin_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 2, WARC_Segment_Total_Length => 2400]);
  $collection = assemble WARC::Collection $index;

  $record = $collection->search(record_id => '<urn:test:record-1:segment-1>');

  $fail = 0;
  eval {_read WARC::Record::Logical $record; $fail = 1;};
  ok($fail == 0 && $@ =~ m/failed to locate any continuation segments/,
     'loading logical record croaks if no continuation segments found (2)')
    or diag($@);

  $index = attach WARC::Index::_TestMock
    ([WARC_Type => 'resource', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 1],
     [WARC_Type => 'continuation', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-3>',
      WARC_Segment_Origin_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 3, WARC_Segment_Total_Length => 3600]);
  $collection = assemble WARC::Collection from => $index;

  $record = $collection->search(record_id => '<urn:test:record-1:segment-1>');

  ($fail, $warnings, $warned) = (0, 0, 0);
  eval {_read WARC::Record::Logical $record; $fail = 1;};
  ok($fail == 0 && $@ =~ m/logical record segment missing/,
     'loading logical record croaks if middle segment is missing')
    or diag($@);
  ok($warnings == 1 && $warned == 1, 'only expected warning produced');

  {
    package WARC::Collection::_BogusTestMock1;

    sub searchable { return 1 }
    sub search {
      return new WARC::Record::_TestMock
	(-1, $_[0], WARC_Type => 'continuation', Content_Length => 1400,
	 WARC_Record_ID => '<urn:test:bogus-segment>',
	 WARC_Segment_Origin_ID => '<urn:test:bogus-record>',
	 WARC_Segment_Number => 2);
      }
  }
  $record = $index->search(record_id =>
			   '<urn:test:record-1:segment-1>')->record
    (collection => (bless [], 'WARC::Collection::_BogusTestMock1'));
  ($fail, $warnings, $warned) = (0, 0, 0);
  eval {_read WARC::Record::Logical $record; $fail = 1;};
  ok($fail == 0 && $@ =~ m/segment not part of record/,
     'loading logical record croaks if bogus segment slipped into index')
    or diag($@);
  ok($warnings == 1 && $warned == 1, 'only expected warning produced');
}

note('*' x 60);

# Basic tests with valid record sets from collection
{
  my $index = attach WARC::Index::_TestMock
    ([WARC_Type => 'resource', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-1>',
      WARC_Block_Digest => 'test:ABCD',
      WARC_Segment_Number => 1],
     [WARC_Type => 'continuation', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-2>',
      WARC_Block_Digest => 'test:EFGH', WARC_Payload_Digest => 'test:1234',
      WARC_Segment_Origin_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 2, WARC_Segment_Total_Length => 2400]);
  my $collection = assemble WARC::Collection from => $index;

  my $member = $collection->search(record_id =>
				   '<urn:test:record-1:segment-1>');
  my $lrec = _read WARC::Record::Logical $member;

  note($lrec->_dbg_dump);

  is(scalar $lrec->segments, 2, 'logical record has two segments');
  is_deeply([map {$_->id} $lrec->segments],
	    ['<urn:test:record-1:segment-1>', '<urn:test:record-1:segment-2>'],
	    'logical record built from first segment finds both segments');
  is_deeply([map {$_->{logical}} $lrec->segments], [$lrec, $lrec],
	    '... and both segments have backlinks to logical record');
  is($lrec->field('Content-Length'), 2400,
     'logical record has total length as "Content-Length"');
  ok((not defined $lrec->field('WARC-Segment-Total-Length')),
     'logical record does not have "WARC-Segment-Total-Length"');
  ok((not defined $lrec->field('WARC-Block-Digest')),
     'logical record does not have "WARC-Block-Digest"');
  is_deeply([map {$_->field('WARC-Block-Digest')} $lrec->segments],
	    ['test:ABCD', 'test:EFGH'],
	    '... but the segments do');
  is($lrec->field('WARC-Payload-Digest'), 'test:1234',
     'logical record gains "WARC-Payload-Digest" from final segment');
  is($lrec->logical, $lrec, 'logical record is its own logical record');
  is($lrec->protocol, 'protocol 0',
     'logical record delegates "protocol" method correctly (1)');
  is($lrec->volume, 'volume 0',
     'logical record delegates "volume" method correctly (1)');
  is($lrec->offset, '0',
     'logical record delegates "offset" method correctly (1)');
  is($lrec->next, 'next 1',
     'logical record delegates "next" method correctly (1)');
  isa_ok(tied *{$lrec->open_block}, 'WARC::Record::Logical::Block',
	 'tied object for "open_block"');
  isa_ok(tied *{$lrec->open_continued}, 'WARC::Record::Logical::Block',
	 'tied object for "open_continued"');

  $member = $collection->search(record_id => '<urn:test:record-1:segment-2>');
  $lrec = _read WARC::Record::Logical $member;

  note($lrec->_dbg_dump);

  is(scalar $lrec->segments, 2, 'logical record has two segments');
  is_deeply([map {$_->id} $lrec->segments],
	    ['<urn:test:record-1:segment-1>', '<urn:test:record-1:segment-2>'],
	    'logical record built from last segment finds both segments');
  is_deeply([map {$_->{logical}} $lrec->segments], [$lrec, $lrec],
	    '... and both segments have backlinks to logical record');
  is($lrec->field('Content-Length'), 2400,
     'logical record has total length as "Content-Length"');
  ok((not defined $lrec->field('WARC-Segment-Total-Length')),
     'logical record does not have "WARC-Segment-Total-Length"');
  ok((not defined $lrec->field('WARC-Block-Digest')),
     'logical record does not have "WARC-Block-Digest"');
  is_deeply([map {$_->field('WARC-Block-Digest')} $lrec->segments],
	    ['test:ABCD', 'test:EFGH'],
	    '... but the segments do');
  is($lrec->field('WARC-Payload-Digest'), 'test:1234',
     'logical record gains "WARC-Payload-Digest" from final segment');
  is($lrec->logical, $lrec, 'logical record is its own logical record');
  is($lrec->protocol, 'protocol 0',
     'logical record delegates "protocol" method correctly (2)');
  is($lrec->volume, 'volume 0',
     'logical record delegates "volume" method correctly (2)');
  is($lrec->offset, '0',
     'logical record delegates "offset" method correctly (2)');
  is($lrec->next, 'next 1',
     'logical record delegates "next" method correctly (2)');
  isa_ok(tied *{$lrec->open_block}, 'WARC::Record::Logical::Block',
	 'tied object for "open_block"');
  isa_ok(tied *{$lrec->open_continued}, 'WARC::Record::Logical::Block',
	 'tied object for "open_continued"');
}

note('*' x 60);

# Basic tests with valid record sets needing heuristics
{
  my $index = attach WARC::Index::_TestMock
    ([WARC_Type => 'resource', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 1],
     [WARC_Type => 'continuation', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-2>',
      WARC_Segment_Origin_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 2, WARC_Segment_Total_Length => 2400]);

  my $member = $index->search(record_id =>
			      '<urn:test:record-1:segment-1>')->record
				(collection => undef);
  my $fail = 0;
  eval {_read WARC::Record::Logical $member; $fail = 1;};
  ok($fail == 0 && $@ =~ m/failed to locate any continuation segments/,
     'loading logical record croaks if no continuation segments found (3)')
    or diag($@);

  my $lrec;
  {
    local @MOCK_Heuristics_FindRest_Results =
      $index->search(record_id => '<urn:test:record-1:segment-2>')->record
	(collection => undef);
    $lrec = _read WARC::Record::Logical $member;
  }

  is_deeply([map {$_->id} $lrec->segments],
	    ['<urn:test:record-1:segment-1>', '<urn:test:record-1:segment-2>'],
	    'logical record built from first segment via heuristics');

  $member = $index->search(record_id =>
			   '<urn:test:record-1:segment-2>')->record
			     (collection => undef);
  $fail = 0;
  eval {_read WARC::Record::Logical $member; $fail = 1;};
  ok($fail == 0 && $@ =~ m/failed to locate first segment/,
     'loading logical record croaks if first segment not found')
    or diag($@);

  {
    package WARC::Collection::_BogusTestMock2;

    sub searchable { return 1 }
    sub search { return undef }
  }
  $member = $index->search(record_id =>
			   '<urn:test:record-1:segment-2>')->record
    (collection => (bless [], 'WARC::Collection::_BogusTestMock2'));
  $fail = 0;
  {
    my $warnings = 0; my $warned = 0;
    local $SIG{__WARN__} = sub { $warnings++;
				 $warned = 1 if shift =~ m/index failed/ };
    eval {_read WARC::Record::Logical $member; $fail = 1;};
    ok($fail == 0 && $@ =~ m/failed to locate first segment/
       && $warnings == 1 && $warned == 1,
       'loading logical record warns and croaks if index search fails')
      or diag($@);
  }

  $member = $index->search(record_id =>
			   '<urn:test:record-1:segment-2>')->record
    (collection => undef);
  {
    local @MOCK_Heuristics_FindFirst_Results =
      $index->search(record_id => '<urn:test:record-1:segment-1>')->record
	(collection => undef);
    $lrec = _read WARC::Record::Logical $member;
  }

  is_deeply([map {$_->id} $lrec->segments],
	    ['<urn:test:record-1:segment-1>', '<urn:test:record-1:segment-2>'],
	    'logical record built from second segment via heuristics');

  $index = attach WARC::Index::_TestMock
    ([WARC_Type => 'resource', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 1],
     [WARC_Type => 'continuation', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-2>',
      WARC_Segment_Origin_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 2],
     [WARC_Type => 'continuation', Content_Length => 1200,
      WARC_Record_ID => '<urn:test:record-1:segment-3>',
      WARC_Segment_Origin_ID => '<urn:test:record-1:segment-1>',
      WARC_Segment_Number => 3, WARC_Segment_Total_Length => 3600]);
  {
    local @MOCK_Heuristics_FindFirst_Results =
      ($index->search(record_id => '<urn:test:record-1:segment-1>')->record
       (collection => undef),
       $index->search(record_id => '<urn:test:record-1:segment-2>')->record
       (collection => undef),
       $index->search(record_id => '<urn:test:record-1:segment-2>')->record
       (collection => undef),
       $index->search(record_id => '<urn:test:record-1:segment-2>')->record
       (collection => undef),
       $index->search(record_id => '<urn:test:record-1:segment-3>')->record
       (collection => undef));
    $lrec = _read WARC::Record::Logical $member;
  }

  is_deeply([map {$_->id} $lrec->segments],
	    ['<urn:test:record-1:segment-1>', '<urn:test:record-1:segment-2>',
	     '<urn:test:record-1:segment-3>'],
	    'logical record built via heuristics skipping duplicates');

}

note('*' x 60);

# Large record tests
{
  # Realistically, Math::BigInt will only be used on 32-bit machines but
  #  we can fake records large enough to ensure its use for code coverage.

  my $giant_segment_size = 1<<(8 * $Config{ivsize} - 2);
  my @giant_segments =
    map {[WARC_Type => 'continuation', Content_Length => $giant_segment_size,
	  WARC_Record_ID => "<urn:test:record-1:segment-$_>",
	  WARC_Segment_Origin_ID => '<urn:test:record-1:segment-1>',
	  WARC_Segment_Number => $_]} 1 .. 16;
  $giant_segments[0][1] = 'resource';	# set initial WARC-Type
  splice @{$giant_segments[0]}, 6, 2;	# remove WARC-Segment-Origin-ID
  my $total_length = Math::BigInt->bzero();
  $total_length->badd($_->[3]) for @giant_segments; # sum Content-Length
  push @{$giant_segments[-1]},
    WARC_Segment_Total_Length => $total_length->bstr();

  note(map { my @i = @$_;
	     my $r = sprintf '- %s: %s%s', (splice @i, 0, 2), "\n";
	     $r   .= sprintf '  %s: %s%s', (splice @i, 0, 2), "\n" while @i;
	     $r } @giant_segments);

  my $index = attach WARC::Index::_TestMock @giant_segments;
  my $collection = assemble WARC::Collection from => $index;

  my $member = $collection->search(record_id =>
				   '<urn:test:record-1:segment-1>');
  my $lrec = _read WARC::Record::Logical $member;

  note($lrec->_dbg_dump);

  is(scalar $lrec->segments, 16,'large record has 16 segments');
  is_deeply([map {$_->id} $lrec->segments],
	    [map {"<urn:test:record-1:segment-$_>"} 1 .. 16],
	    'large record has expected segment record-ID values');
  ok((not defined $lrec->field('WARC-Segment-Total-Length')),
     'large record does not have "WARC-Segment-Total-Length"');
  cmp_ok($lrec->field('Content-Length'), 'eq', $total_length->bstr(),
	 'large record has total length as "Content-Length"');
}

note('*' x 60);

# Verify construction/destruction balances
{
  is($WARC::Record::Logical::_total_destroyed,
     $WARC::Record::Logical::_total_read,
     'all WARC::Record::Logical objects destroyed');
  is($WARC::Record::_TestMock::_total_destroyed,
     $WARC::Record::_TestMock::_total_constructed,
     'all mock WARC::Record objects destroyed');
}

note(<<"EOR")
objects constructed/destroyed during test:
  mock WARC::Record         $WARC::Record::_TestMock::_total_destroyed
  WARC::Record::Logical     $WARC::Record::Logical::_total_destroyed
EOR
