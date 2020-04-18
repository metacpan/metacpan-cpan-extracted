# Unit tests for WARC::Index::Entries module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests => 2 + 8;

BEGIN { use_ok('WARC::Index::Entries')
	  or BAIL_OUT "WARC::Index::Entries failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Index::Entries v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Index::Entries version check')
}

{
  package WARC::Index::_TestMock::Entry;

  our @ISA = qw(WARC::Index::Entry);

  sub value { $_[0]->{$_[1]} }

  sub record_offset { (shift)->value('record_offset') }
  sub volume { (shift)->value('volume') }
  sub record { 'mock record '.($_[0]->volume).'!'.($_[0]->record_offset) }
}
sub make_test_entry ($) {
  my $data = shift;
  bless $data, 'WARC::Index::_TestMock::Entry';
}

note('*' x 60);

# Basic tests
{
  my @base = (volume => 'mock volume', record_offset => 0);

  my $entry = make_test_entry {@base, id => '<urn:test:record-1>'};
  is($entry, (coalesce WARC::Index::Entries [$entry]),
     'pass through single entry');

  $entry = coalesce WARC::Index::Entries
    ([make_test_entry {@base, id => '<urn:test:record-1>'},
      make_test_entry {@base, url => 'http://warc.test/foo'}]);

  {
    my $fail = 0;
    eval {my $index = $entry->index; $fail = 1;};
    ok($fail == 0 && $@ =~ m/coalesced.*entry.*not.*one.*index/,
       'index method croaks');
  }

  is($entry->volume, 'mock volume',	'volume method returns value');
  is($entry->record_offset, 0,		'record_offset method returns value');
  is($entry->record, 'mock record mock volume!0',
					'record method returns mock record');
  is($entry->value('id'), '<urn:test:record-1>',
					'value "id" found');
  is($entry->value('url'), 'http://warc.test/foo',
					'value "url" found');
  ok((not defined $entry->value('time')),
					'no "time" value in indexes');
}
