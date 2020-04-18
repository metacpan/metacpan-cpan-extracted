# Unit tests for WARC::Index::Entry module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

my @Index_distance_tests;
BEGIN {
  @Index_distance_tests =
    # each element: hash of index entry data followed by
    #		     query/summary/report triplets
    ([ {url => 'http://example.com/foo/bar'} =>
       [url => 'http://example.com/'] => -1, [url => -1],
       [url_prefix => 'http://example.com/'] => 7, [url_prefix => 7],
       [url_prefix => 'http://example.com/foo'] => 4, [url_prefix => 4],
       [url_prefix => 'http://example.com/bar'] => -1, [url_prefix => -1],
       [url => 'http://example.com/foo/bar', time => time]
       => 0, [url => 0, time => undef]],
     [ {url => 'http://example.com/', time => 1568164455} =>
       [url => 'http://example.com/foo'] => -1, [url => -1],
       [url_prefix => 'http://example.com/foo'] => -1, [url_prefix => -1],
       [url => 'http://example.com/foo', time => 1568164477]
       => -23, [url => -1, time => 22],
       [url => 'http://example.com/', time => 1568164477]
       => 22, [url => 0, time => 22],
       [url => 'http://example.com/', time => 1568164455]
       => 0, [url => 0, time => 0]],
     [ {time => 1568164455, record_id => '<urn:test:record-1>'} =>
       [url => 'http://example.com/'] => undef, [url => undef],
       [record_id => '<urn:test:record-2>'] => -1, [record_id => -1],
       [record_id => '<urn:test:record-1>'] => 0, [record_id => 0],
       [record_id => [qw/<urn:test:record-2> <urn:test:record-1>/]]
       => 0, [record_id => 0],
       [record_id => [qw/<urn:test:record-2> <urn:test:record-3>/]]
       => -1, [record_id => -1]],
     [ {url => 'http://example.com/foo/bar/baz', time => 1568164455,
	record_id => '<urn:test:record-2>'} =>
       [url => [qw(http://example.com/foo/bar http://example.com/foo/bar/baz)]]
       => 0, [url => 0],
       [time => [1568164466, 1568164477]] => 11, [time => 11],
       [time => [1568164477, 1568164466]] => 11, [time => 11],
       [url_prefix => [qw(http://example.com/foo/bar http://example.com/)]]
       => 4, [url_prefix => 4],
       [url_prefix => [qw(http://example.com/ http://example.com/foo/bar)]]
       => 4, [url_prefix => 4]],
    );
}

use Test::More tests
  => 2	# loading tests
  +  4	# abstract method tests
  +  4	# distance special tests
  + scalar @Index_distance_tests
  +  1	# bogus schema test
  +  3;	# record and tag tests

BEGIN { $INC{'WARC/Record/Stub.pm'} = 'mocked in test driver' }
BEGIN { $INC{'WARC/Volume.pm'} = 'mocked in test driver' }

BEGIN { use_ok('WARC::Index::Entry')
	  or BAIL_OUT "WARC::Index::Entry failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Index::Entry v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Index::Entry version check')
}

note('*' x 60);

# abstract methods fail
{
  my $entry = bless {}, 'WARC::Index::Entry'; # make a fake object

  my $fail = 0;
  eval { $entry->index; $fail = 1 };
  ok($fail == 0 && $@ =~ m/abstract base class/,
     'index in base class dies');

  $fail = 0;
  eval { $entry->volume; $fail = 1 };
  ok($fail == 0 && $@ =~ m/abstract base class/,
     'volume in base class dies');

  $fail = 0;
  eval { $entry->record_offset; $fail = 1 };
  ok($fail == 0 && $@ =~ m/abstract base class/,
     'record_offset in base class dies');

  $fail = 0;
  eval { $entry->value; $fail = 1 };
  ok($fail == 0 && $@ =~ m/abstract base class/,
     'value in base class dies');
}

note('*' x 60);

# distance gives warning or exception on bogus calls
{
  my $entry = bless {}, 'WARC::Index::Entry'; # make a fake object

  {
    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned = 1 if (shift) =~ m/void context/ };
    $entry->distance(foo => 1);
    ok($warned == 1,
       'calling distance method in void context produces warning');
  }

  {
    my $fail = 0;
    eval {my $summary = $entry->distance(); $fail = 1;};
    ok($fail == 0 && $@ =~ m/no arguments/,
       'calling distance method with no arguments croaks');

    $fail = 0;
    eval {my $summary = $entry->distance('bogus'); $fail = 1;};
    ok($fail == 0 && $@ =~ m/odd number of arguments/,
       'calling distance method with odd number of arguments croaks');

    $fail = 0;
    eval {my $summary = $entry->distance(bogus => 1); $fail = 1;};
    ok($fail == 0 && $@ =~ m/unknown item bogus/,
       'calling distance method with unknown item croaks');
  }
}

note('*' x 60);

# distance evaluation tests
{
  package WARC::Index::_TestMock::Entry;

  our @ISA = qw(WARC::Index::Entry);

  sub value { $_[0]->{$_[1]} }

  sub record_offset { (shift)->value('record_offset') }
  sub volume { (shift)->value('volume') }
}
sub make_test_entry ($) {
  my $data = shift;
  bless $data, 'WARC::Index::_TestMock::Entry';
}

{
  for (my $i = 0; $i < @Index_distance_tests; $i++) {
    my $test = $Index_distance_tests[$i];
    my $entry = make_test_entry $test->[0];
    subtest "verify test index entry $i" => sub {
      my $query; my $e_s; my $e_r;
      for (my $j = 0; 1+3*$j < @$test; $j++) {
	($query, $e_s, $e_r) = @$test[1+3*$j..3+3*$j];
	my $summary = $entry->distance(@$query);
	my @report = $entry->distance(@$query);
	is($summary, $e_s,		"query $i:$j summary");
	is_deeply(\@report, $e_r,	"query $i:$j report");
      }
    }
  }
}

note('*' x 60);

# bogus schema test
{
  local $WARC::Index::Entry::_distance_value_map{bogus} = [bogus => 'bogus'];
  my $entry = make_test_entry {bogus => 'bogus'};
  my $fail = 0;
  eval {my $summary = $entry->distance(bogus => 1); $fail = 1;};
  ok($fail == 0 && $@ =~ m/unknown mode/,
     'calling distance method with bad schema croaks');
}

note('*' x 60);

# record and tag tests
{
  package WARC::Record::Stub;

  sub new { return join '!', @_[1..$#_] }
}
{
  package WARC::Volume;

  use overload '""' => sub { return 'mock volume' };
  use overload fallback => 1;

  sub _file_tag { return 'mock file tag' }
}

{
  my $volume = bless [], 'WARC::Volume';
  my $entry = make_test_entry { record_offset => 0, volume => $volume };

  is($entry->tag, 'mock file tag:0',	'check index entry tag');
  is($entry->record, 'mock volume!0',	'check mock record stub');
  is($entry->record(more => 'data'), 'mock volume!0!more!data',
					'extra keys passed to stub');
}
