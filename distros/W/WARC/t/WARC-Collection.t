# Unit tests for WARC::Collection module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests =>
     2	# loading tests
  +  6	# assembly tests
  + 34	# search tests (simple)
  +  4;	# search tests (union)


BEGIN { $INC{'WARC/Record/Stub.pm'} = 'mocked in test driver' }

BEGIN { use_ok('WARC::Collection')
	  or BAIL_OUT "WARC::Collection failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Collection v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Collection version check')
}

# Mock indexes with data for WARC::Collection tests
my @Mock_Records;
BEGIN {
  @Mock_Records =
    ([qw=	id		foo		bar		baz=],
     [qw=<urn:test:record-0>	bar		baz/foo		  2=],
     [qw=<urn:test:record-1>	baz		baz/fo		  4=],
     [qw=<urn:test:record-2>	quux		baz/bar		  7=],
     [qw=<urn:test:record-3>	barbaz		baz/bar		  9=],
     [qw=<urn:test:record-4>	quuxbar		quux/a1		 10=],
     [qw=<urn:test:record-5>	bazbar		quux/a2		 12=],
     [qw=<urn:test:record-6>	quuxbaz		quux/a3		 14=],
     [qw=<urn:test:record-7>	quuxbar		quux/a4		 16=],
     [qw=<urn:test:record-8>	quuxbaz		quux/b1		 18=],
     [qw=<urn:test:record-9>	quuxfoo		quux/b2		 20=],
    );
}
my @Mock_Records_Columns = @{shift @Mock_Records};
my %Mock_Records_Columns =
  map {$Mock_Records_Columns[$_] => $_} 0..$#Mock_Records_Columns;

require WARC::Index::Entry;
%WARC::Index::Entry::_distance_value_map =
  ( id	=> [exact	=> 'id'],
    foo	=> [exact	=> 'foo'],
    bar	=> [prefix	=> 'bar'],
    baz	=> [numeric	=> 'baz'],
  );	# override index key schema

{
  package WARC::Record::Stub;

  our $RUN_Collection_Passthrough_Tests = 0;
  use Test::More;

  sub new {
    if ($RUN_Collection_Passthrough_Tests) {
      is($_[3], 'collection',		'stub record given "collection" key');
      isa_ok($_[4], 'WARC::Collection',	'stub record "collection" backlink');
    }
    return $_[1] # return "volume" for testing
  }
}
{
  package WARC::Index::Entry::_TestMock;

  our @ISA = qw(WARC::Index::Entry);

  sub tag { (shift)->[0] }	# use id as tag for testing
  sub volume { (shift)->[0] }	# return id for testing
  sub record_offset { return 0 }# return zero for testing
  sub value { $_[0]->[$Mock_Records_Columns{$_[1]}] }
}
bless $Mock_Records[$_], 'WARC::Index::Entry::_TestMock' for 0..$#Mock_Records;

{
  package WARC::Index::_TestMock;

  our @ISA = qw(WARC::Index);

  # Each index supports only some keys, for which its hash holds a true value.

  sub attach {
    my $class = shift;
    bless {map {$_ => 1} @_}, $class;
  }

  sub searchable { return $_[0]->{$_[1]} }

  sub search {
    my $self = shift;

    for (my $i = 0; $i < @_; $i += 2)
      { last unless $i < @_;
	unless ($self->{$_[$i]}) { splice @_, $i, 2; redo if @_ } }
    return wantarray ? () : undef unless scalar @_;

    my @res = @Mock_Records;
    foreach my $r (@res) {
      next unless defined $r;
      $r = undef unless $r->distance(@_) >= 0;
    }

    if (wantarray) { return grep { defined } @res }
    else {
      @res = map { $_->[0] } sort { $a->[1] <=> $b->[1] }
	map { [$_, scalar $_->distance(@_)] } grep { defined } @res;
      return shift @res;
    }
  }
}
{
  package WARC::Index::_TestMock::I1;

  our @ISA = qw(WARC::Index::_TestMock);

  sub attach {
    my $class = shift;
    my ($col) = (shift) =~ m/^(id|foo|bar|baz)/;

    return $class->SUPER::attach($col)
  }

  WARC::Index::register(filename => qr/[.]idx1$/);
}
{
  package WARC::Index::_TestMock::I2;

  our @ISA = qw(WARC::Index::_TestMock);

  sub attach {
    my $class = shift;
    my ($col1,$col2) = (shift) =~ m/^(id|foo|bar|baz)-(id|foo|bar|baz)/;

    return $class->SUPER::attach($col1, $col2)
  }

  WARC::Index::register(filename => qr/[.]idx2$/);
}

note('*' x 60);

# Assembly tests
{
  {
    my $warnings = 0; my $warned = 0;
    local $SIG{__WARN__} =
      sub {$warnings++;
	   $warned = 1 if shift =~ m/assembling empty collection/};

    my $collection = assemble WARC::Collection ();
    isa_ok($collection, 'WARC::Collection', 'empty collection 1');
    ok($warnings == 1 && $warned == 1,
       'assembling empty collection produces warning (1)');

    $warnings = 0; $warned = 0;
    $collection = assemble WARC::Collection from => ();
    isa_ok($collection, 'WARC::Collection', 'empty collection 2');
    ok($warnings == 1 && $warned == 1,
       'assembling empty collection produces warning (2)');
  }

  {
    my $fail = 0;
    eval {my $collection = assemble WARC::Collection ('bogus'); $fail = 1;};
    ok ($fail == 0 && $@ =~ m/no known handler/,
	'assembling collection with bogus index croaks');
  }

  my $collection = assemble WARC::Collection
    from => 'id.idx1', attach WARC::Index::_TestMock::I1 ('foo.idx1');

  isa_ok($collection, 'WARC::Collection', 'collection object');
}

note('*' x 60);

# Search tests (simple)
{
  my $collection = assemble WARC::Collection from => 'id.idx1', 'foo.idx1';

  {
    my $warnings = 0; my $warned = 0;
    local $SIG{__WARN__} =
      sub {$warnings++;
	   $warned = 1 if shift =~ m/calling.*method in void context/};

    $collection->search(id => 'bogus');
    ok($warnings == 1 && $warned == 1,
       'calling collection search method in void context produces warning');
  }

  {
    my $fail = 0;
    eval {my $r = $collection->search(); $fail = 1;};
    ok($fail == 0 && $@ =~ m/no arguments given/,
       'searching collection with no criteria croaks');

    $fail = 0;
    eval {my $r = $collection->search('bogus'); $fail = 1;};
    ok($fail == 0 && $@ =~ m/odd number of arguments/,
       'searching collection with odd number of arguments croaks');
  }

  ok(($collection->searchable('id')),
     'collection with "id" and "foo" indexes can search by "id"');
  ok(($collection->searchable('foo')),
     'collection with "id" and "foo" indexes can search by "foo"');
  ok((not $collection->searchable('bar')),
     'collection with "id" and "foo" indexes cannot search by "bar"');
  ok((not $collection->searchable('baz')),
     'collection with "id" and "foo" indexes cannot search by "baz"');

  my @results = $collection->search(foo => 'quux');
  is(scalar @results, 1, 'search by unique value returns one result');
  is($results[0], '<urn:test:record-2>',
     'search by unique value returns correct result');

  @results = $collection->search(foo => 'quuxbar');
  is(scalar @results, 2, 'search by non-unique value returns multiple results');
  is_deeply([sort @results], [qw/<urn:test:record-4> <urn:test:record-7>/],
	    'search by non-unique value returns correct results');

  @results = $collection->search(foo => 'quuxbaz', bar => 'quux/b');
  is(scalar @results, 2, 'key unknown to index ignored in search');
  is_deeply([sort @results], [qw/<urn:test:record-6> <urn:test:record-8>/],
	    '... and search returns full results');

  $collection = assemble WARC::Collection 'id.idx1', 'foo-bar.idx2';
  isa_ok($collection, 'WARC::Collection', 'collection object');

  {
    local $WARC::Record::Stub::RUN_Collection_Passthrough_Tests = 1;
    @results = $collection->search(foo => 'quuxbaz', bar => 'quux/b');
    is(scalar @results, 1,
       'search by pair unique across indexes returns one result');
    is($results[0], '<urn:test:record-8>',
       'search by pair unique across indexes returns correct result');

    @results = $collection->search(bar => 'baz/f');
    is(scalar @results, 2,	'search by prefix produces two results');
    is_deeply([@results], [qw/<urn:test:record-1> <urn:test:record-0>/],
	      '... and sorts them by suffix length');

    my $result = $collection->search(bar => 'baz/f');
    is($result, '<urn:test:record-1>',
       'correct best match for search by prefix');
  }

  $collection = assemble WARC::Collection 'id.idx1', 'bar-baz.idx2';
  @results = $collection->search(bar => 'baz', baz => 5);
  is(scalar @results, 4,
     'search by prefix and number produces four results');
  is_deeply([@results], [qw/<urn:test:record-1> <urn:test:record-2>
			    <urn:test:record-0> <urn:test:record-3>/],
	    '... and sorts them by numeric distance');
  my $result = $collection->search(baz => 16);
  is($result, '<urn:test:record-7>',
     'correct best match for search by number');

  # these check the special case of a single index
  $collection = assemble WARC::Collection from => 'id.idx1';
  @results = $collection->search(id => '<urn:test:record-0>');
  is_deeply([@results], ['<urn:test:record-0>'],
	    'search by id produces unique result');
  $result = $collection->search(id => '<urn:test:record-9>');
  is($result, '<urn:test:record-9>',	'search by id produces match');

  @results = $collection->search(foo => 'quux');
  is(scalar @results, 0,	'search by unknown key produces empty list');
  $result = $collection->search(foo => 'quux');
  ok((not defined $result),	'search by unknown key produces no match');
}

note('*' x 60);

# Search tests (union)
{
  my $collection = assemble WARC::Collection from => 'id.idx1';

  my @results = $collection->search
    (id => [qw/<urn:test:record-0> <urn:test:record-5>/]);
  is_deeply([sort @results], [qw/<urn:test:record-0> <urn:test:record-5>/],
	    'search single index for multiple record ids');

  $collection = assemble WARC::Collection from => 'id-foo.idx2';

  @results = $collection->search
    (id => [qw/<urn:test:record-4> <urn:test:record-6>
	       <urn:test:record-7> <urn:test:record-9>/],
     foo => 'quuxfoo');
  is_deeply([sort @results],
	    [qw/<urn:test:record-9>/],
	    'search multi-column index for multiple ids and unique match');

  @results = $collection->search
    (id => [qw/<urn:test:record-4> <urn:test:record-6>
	       <urn:test:record-7> <urn:test:record-9>/],
     foo => 'quuxbar');
  is_deeply([sort @results],
	    [qw/<urn:test:record-4> <urn:test:record-7>/],
	    'search multi-column index for multiple ids and two matches');


  @results = $collection->search
    (id => [qw/<urn:test:record-4> <urn:test:record-6>
	       <urn:test:record-7> <urn:test:record-9>/],
     foo => [qw/quuxbar quuxbaz/]);
  is_deeply([sort @results],
	    [qw/<urn:test:record-4> <urn:test:record-6>
		<urn:test:record-7>/],
	    'search multi-column index for multiple ids and matches');

}
