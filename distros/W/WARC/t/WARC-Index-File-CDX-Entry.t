# Unit tests for WARC::Index::File::CDX::Entry module		# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests => 3 + 11;

BEGIN { use_ok('WARC::Index::File::CDX::Entry')
	  or BAIL_OUT "WARC::Index::File::CDX::Entry failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Index::File::CDX::Entry v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Index::File::CDX::Entry version check')
}

isa_ok('WARC::Index::File::CDX::Entry', 'WARC::Index::Entry',
       'WARC::Index::File::CDX::Entry');

{
  package WARC::Index::_TestMock;

  sub entry_at { return $_[1] }
}

sub make_test_entry {
  bless {_index => (bless {}, 'WARC::Index::_TestMock'),
	 _g__volume => 'mock volume',
	 _entry_offset => 17, _entry_length => 23,
	 _Vv__record_offset => 42,
	 @_}, 'WARC::Index::File::CDX::Entry'
}

note('*' x 60);

# Basic tests
{
  my $entry = make_test_entry foo => 'bar', baz => 'quux';

  isa_ok($entry, 'WARC::Index::File::CDX::Entry', 'test entry');
  isa_ok($entry, 'WARC::Index::Entry', 'test entry');

  is(ref $entry->index, 'WARC::Index::_TestMock',
     'test entry index backlink');
  is($entry->volume, 'mock volume',	'test entry volume backlink');
  is($entry->entry_position, 17,	'test entry position');
  is($entry->record_offset, 42,		'test entry record offset');
  is($entry->next, (17+23),		'test entry next lookup');
  is($entry->value('foo'), 'bar',	'test entry value "foo"');
  is($entry->value('baz'), 'quux',	'test entry value "baz"');

  ok((not defined $entry->value('_g__volume')),
     'test entry hides internal value "_g__volume"');
  ok((not defined $entry->value('_index')),
     'test entry hides internal value "_index"');
}
