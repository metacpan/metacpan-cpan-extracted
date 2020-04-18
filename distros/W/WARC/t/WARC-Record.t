# Unit tests for WARC::Record module				# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests => 2 + 32 + 8;
BEGIN { use_ok('WARC::Record')
	  or BAIL_OUT "WARC::Record failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Record version check')
}

note('*' x 60);

require HTTP::Response;

# Basic tests
{
  {
    my $fail = 0;
    eval {new WARC::Record (); $fail = 1;};
    ok($fail == 0 && $@ =~ m/required field.*not/,
			'reject construction with no parameters');
  }

  my $r1 = new WARC::Record (type => 'metadata');

  note($r1->_dbg_dump);

  isa_ok($r1, 'WARC::Record',	'new record');
  is($r1->field('WARC-Type'), 'metadata',
				'construction sets "WARC-Type" field');
  is($r1->type, 'metadata',	'type getter also returns type');

  note($r1->_dbg_dump);

  $r1->fields->{WARC_Record_ID} = '<urn:test:record-1>';
  is($r1->field('WARC-Record-ID'), '<urn:test:record-1>',
				'setting record ID works');
  is($r1->id, '<urn:test:record-1>',
				'id getter returns record ID');

  note($r1->_dbg_dump);

  $r1->fields->{WARC_Date} = '2019-09-08T00:19:30Z';
  is($r1->field('WARC-Date'), '2019-09-08T00:19:30Z',
				'setting record datestamp works');
  is($r1->date->as_string, '2019-09-08T00:19:30Z',
				'date getter returns datestamp object');

  note($r1->_dbg_dump);

  ok((not defined $r1->content_length),
				'content_length initially undefined');

  ok((not defined $r1->protocol),
				'no protocol for in-memory record');
  ok((not defined $r1->volume),	'no volume for in-memory record');
  ok((not defined $r1->offset),	'no offset for in-memory record');
  ok((not defined $r1->next),	'no next record for in-memory record');

  ok((not defined $r1->logical),'no logical record for in-memory record');
  ok((not defined $r1->segments),'no segments for in-memory record');

  ok((not defined $r1->open_block),
     'method "open_block" returns nothing for in-memory record');
  ok((not defined $r1->open_continued),
     'method "open_continued" returns nothing for in-memory record');
  ok((not defined $r1->replay),
     'method "replay" returns nothing for in-memory record');
  ok((not defined $r1->open_payload),
     'method "open_payload" returns nothing for in-memory record');

  my $r2 = new WARC::Record (type => 'metadata');

  isa_ok($r2, 'WARC::Record',	'second new record');

  cmp_ok($r1, '!=', $r2,	'new records are different');
  cmp_ok($r1, '==', $r1,	'first record is equal to itself');
  cmp_ok($r2, '==', $r2,	'second record is equal to itself');
  ok(((($r1 > $r2) xor ($r2 > $r1)) && (($r1 < $r2) xor ($r2 < $r1))),
				'records are in a consistent ordering');

  my $data = new WARC::Fields (foo => 1, bar => 2);
  $r1->block($data);	# WARC::Fields has an as_block method
  is($r1->block, $data->as_block, 'set block from WARC::Fields object');
  is($r1->content_length, length $data->as_block,
     'setting block also sets "Content-Length" field (1)');

  $data = WARC::Date->now();
  $r1->block($data);	# WARC::Date has an as_string method
  is($r1->block, $data->as_string, 'set block from WARC::Date object');
  is($r1->content_length, length $data->as_string,
     'setting block also sets "Content-Length" field (2)');

  $data = new HTTP::Response (200, 'OK');
  $r1->block($data);	# Test special handling of HTTP message objects
  is($r1->block, $data->as_string("\015\012"),
     'set block from HTTP response object');
  is($r1->content_length, length $data->as_string("\015\012"),
     'setting block also sets "Content-Length" field (3)');

  $data = 'some sample text';
  $r1->block($data);
  is($r1->block, $data, 'set block from string');

  {
    { package WARC::_TestMock::Empty }
    my $fail = 0;
    eval {$r1->block(bless {}, 'WARC::_TestMock::Empty'); $fail = 1};
    ok($fail == 0 && $@ =~ m/unrecognized object/,
       'reject setting block from other object');
  }
}

note('*' x 60);

# Mock record type for extended comparison tests
{
  package WARC::Record::_TestMock;

  our @ISA = qw(WARC::Record);

  sub compareTo { my ($a, $b, $swap) = @_; $b->compareTo($a, !$swap) }
  sub volume { return 'test volume' }
}

# Extended comparison tests
{
  my $r2 = new WARC::Record::_TestMock (type => 'metadata');
  my $r1 = new WARC::Record (type => 'metadata');

  isa_ok($r1, 'WARC::Record',	'first record');
  isa_ok($r2, 'WARC::Record',	'second record');

  cmp_ok($r1, '<', $r2,		'sort "disk" record after in-memory record');
  cmp_ok($r2, '>', $r1,		'sort in-memory record before "disk" record');

  cmp_ok($r1->compareTo($r2), '<', 0,
				'sort memory record ahead of "disk" record');
  cmp_ok($r1->compareTo($r2, 1), '>', 0,
				'sort memory record ahead of "disk" record (swap)');

  cmp_ok($r2->compareTo($r1), '>', 0,
				'sort "disk" record after memory record');
  cmp_ok($r2->compareTo($r1, 1), '<', 0,
				'sort "disk" record after memory record (swap)');
}
