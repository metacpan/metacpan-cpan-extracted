# Unit tests for WARC::Record::Payload module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests =>
     2	# loading tests
  +  2	# basic tests with/without deferred loading
  ;

BEGIN { use_ok('WARC::Record::Payload')
	  or BAIL_OUT "WARC::Record::Payload failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record::Payload v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/ version v9999.*required--this is only version/,
     'WARC::Record::Payload version check')
}

use File::Spec;
use Fcntl qw/SEEK_SET SEEK_CUR/;

BAIL_OUT 'sample WARC file not found'
  unless -f File::Spec->catfile($Bin, 'test-file-2.warc');

require WARC::Volume;

my %Index = ();		# map: record ID => offset
my $Volume = mount WARC::Volume File::Spec->catfile($Bin, 'test-file-2.warc');
for (my $record = $Volume->first_record; $record; $record = $record->next)
  { $Index{$record->field('WARC-Record-ID')} = $record->offset }

note('*' x 60);

# Basic tests
sub run_basic_tests {
  plan tests => 3 + 3 + 6 + 8;
  my $record = $Volume->record_at($Index{'<urn:test:file-2:record-1>'});
  my $payload = $record->open_payload;

  note((tied *$payload)->_dbg_dump);
  ok((eof $payload),		'empty payload handle starts at EOF');
  is(scalar <$payload>, undef,	'read line from empty payload');
  is(getc $payload, undef,	'read character from empty payload');

  $record = $Volume->record_at($Index{'<urn:test:file-2:record-2>'});
  $payload = $record->open_payload;

  ok((not eof $payload),	'payload with data initially not at EOF');
  is_deeply
    ([<$payload>],
     [qq!"What is the sound of Perl? Is it not the sound of a wall that\n!,
      qq!people have stopped banging their heads against?"\n!,
      qq!--Larry Wall in <1992Aug26.184221.29627.com>\n!],
     'read payload contents as list of lines');
  ok((eof $payload),		'payload with data now at EOF');
  note((tied *$payload)->_dbg_dump);
  close $payload;

  $record = $Volume->record_at($Index{'<urn:test:file-2:record-5>'});
  $payload = $record->open_payload;

  is_deeply([map {getc $payload} 1..8], [split //, q/And don'/],
	    'read characters from payload with data');
  is(scalar <$payload>,
     qq!t tell me there isn't one bit of difference between null and space,\n!,
     'read rest of line 1');
  note((tied *$payload)->_dbg_dump);
  is(scalar <$payload>,
     qq!because that's exactly how much difference there is. :-)\n!,
     'read line 2');
  is(scalar <$payload>,
     qq!--- Larry Wall in <10209\@jpl-devvax.JPL.NASA.GOV>\n!,
     'read line 3');
  is(scalar <$payload>, undef,	'EOF reached after line 3');
  ok((eof $payload),		'payload now at EOF');
  note((tied *$payload)->_dbg_dump);

  $record = $Volume->record_at($Index{'<urn:test:file-2:record-8>'});
  $payload = $record->open_payload;

  {
    my $buf;

    is(seek($payload, 10, SEEK_SET), 1, 'seek within payload');
    is(read($payload, $buf, 10), 10,	'read after seek (result)');
    is($buf, 'charitable',		'read after seek (data)');
    is(tell($payload), 20,		'tell after seek and read');
    is(seek($payload, 19, SEEK_CUR), 1,	'seek again');
    is(read($payload, $buf, 7, 4), 7,	'read with offset (result)');
    is($buf, 'charleading',		'read with offset (data)');
    is(tell($payload), 46,		'tell after second read');
  }
}

{
  subtest 'basic tests without deferred loading' => \&run_basic_tests;

  no warnings qw(once);
  local $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 0;
  subtest 'basic tests with deferred loading' => \&run_basic_tests;
}
