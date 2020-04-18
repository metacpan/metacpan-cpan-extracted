# Unit tests for WARC::Volume module				# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests => 2 + 11 + 5;
BEGIN { use_ok('WARC::Volume')
	  or BAIL_OUT "WARC::Volume failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Volume v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Volume version check')
}

use Cwd qw/abs_path/;
use Errno qw/ENOENT/;
use File::Spec::Functions qw/catfile/;

# Redefine the only subroutine in WARC::Record::FromVolume that
#  WARC::Volume actually calls.  Because this is mocked, WARC::Volume
#  objects constructed during this test need not refer to valid WARC files.

my $records_read = 0;
my $record_offset = '';
my $record = 'mock test record';

{
  package WARC::Record::FromVolume;

  no warnings 'redefine';

  sub _read { $record_offset = $_[2]; $records_read++; return $record }
}

# Basic tests with non-existent file
{
  BAIL_OUT "what do you mean 'foo-does-not-exist' exists?"
    if -f 'foo-does-not-exist';
  my $volume = mount WARC::Volume ('foo-does-not-exist');

  isa_ok($volume, 'WARC::Volume', 'a WARC::Volume object');

  is($records_read, 1,	'mounting volume reads record');
  is($record_offset, 0,	'mounting volume reads first record');
  is($volume->filename, abs_path('foo-does-not-exist'),
			'volume filename is canonical file name');

  {
    my $ENOENT_message = '';
    { local $! = ENOENT; $ENOENT_message = "$!" }

    BAIL_OUT "could not get message for ENOENT" unless $ENOENT_message;

    my $fail = 0;
    eval {my $fh = $volume->open; $fail = 1;};
    ok($fail == 0 && $@ =~ m/$ENOENT_message/,
			'exception thrown on opening non-existent file');
  }

  $record_offset = 'bogus';
  is($volume->first_record, 'mock test record',
			'requesting first record returns mock value');
  is($record_offset, 0,	'requesting first record reads offset 0');
  is($records_read, 2,	'requesting first record attempts read');

  is($volume->record_at(42), 'mock test record',
			'requesting record at offset returns mock value');
  is($record_offset, 42,'requesting record at offset reads that offset');
  is($records_read, 3,	'requesting record at offset attempts read');
}

# Tests with actual file
{
  my $volume = mount WARC::Volume (catfile($Bin, 'test-file-1.warc'));

  isa_ok($volume, 'WARC::Volume', 'a WARC::Volume object');

  is("$volume", abs_path(catfile($Bin, 'test-file-1.warc')),
			'volume string conversion is canonical file name');

  {
    my $vfh = $volume->open;

    like(scalar <$vfh>, qr/^WARC\/1.0/,
			'read first line of test WARC file');
  }

  my $other = mount WARC::Volume ($0);	# use test script as test file

  is($volume->_file_tag, $volume->_file_tag,
			'volume file tag is stable');
  isnt($volume->_file_tag, $other->_file_tag,
       'test WARC file and test script have distinct file tags');
  diag('test WARC file has tag: ', $volume->_file_tag);
}
