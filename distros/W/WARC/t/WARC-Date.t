# Unit tests for WARC::Date module				# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests => 2 + 14 + 16 + 4;

BEGIN { use_ok('WARC::Date')
	  or BAIL_OUT "WARC::Date failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Date v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Date version check')
}

use Scalar::Util qw/tainted/;

note('*' x 60);

# Input validation tests
{
  my $fail = 0;
  eval {WARC::Date->from_epoch('BOGUS!'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/epoch timestamp is not a number/,
     'reject blatantly bogus epoch timestamp');

  $fail = 0;
  eval {WARC::Date->from_epoch('12345T54321'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/epoch timestamp is not a number/,
     'reject subtly bogus epoch timestamp');

  $fail = 0;
  eval {WARC::Date->from_string('BOGUS!'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/contains invalid character/,
     'reject blatantly bogus string timestamp');

  $fail = 0;
  eval {WARC::Date->from_string('2019-08-16T19:30:30S'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/contains invalid character/,
     'reject subtly bogus string timestamp');

  $fail = 0;
  eval {WARC::Date->from_string('2019-08-16Z19:30:30T'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/not in required format/,
     'reject strangely bogus string timestamp (1)');

  $fail = 0;
  eval {WARC::Date->from_string('2019-08-16TZZ:ZZ:ZZZ'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/not in required format/,
     'reject strangely bogus string timestamp (2)');

  $fail = 0;
  eval {WARC::Date->from_string('2019-08-16T19:30:30'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/not in required format/,
     'reject string timestamp without "Z"');

  $fail = 0;
  eval {WARC::Date->from_string('19:30:30Z2019-08-16'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/not in required format/,
     'reject string timestamp in other format (1)');

  $fail = 0;
  eval {WARC::Date->from_string('19-08-16T19:30:30Z'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/not in required format/,
     'reject string timestamp in other format (2)');

  $fail = 0;
  eval {WARC::Date->from_string('2019-13-16T19:30:30Z'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/not valid as timestamp/,
     'reject string timestamp with out-of-range month');

  $fail = 0;
  eval {WARC::Date->from_string('2019-08-32T19:30:30Z'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/not valid as timestamp/,
     'reject string timestamp with out-of-range day');

  $fail = 0;
  eval {WARC::Date->from_string('2019-08-16T24:30:30Z'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/not valid as timestamp/,
     'reject string timestamp with out-of-range hour');

  $fail = 0;
  eval {WARC::Date->from_string('2019-08-16T19:60:30Z'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/not valid as timestamp/,
     'reject string timestamp with out-of-range minutes');

  $fail = 0;
  eval {WARC::Date->from_string('2019-08-16T19:30:61Z'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/not valid as timestamp/,
     'reject string timestamp with out-of-range seconds');
}

note('*' x 60);

# Basic tests with valid data
{
  my $now = time;
  my $date = WARC::Date->now;

  isa_ok($date, 'WARC::Date',	'current time as a WARC::Date');

  cmp_ok($date->as_epoch - $now, '<', 2,
				'construct WARC::Date for current time');
  cmp_ok($date - $now, '<', 2,	'... also tested with numeric conversion');
  cmp_ok($date, '>=', $now,	'timestamps in expected order');

  like($date->as_string, qr/^\d{4}(?:-\d{2}){2}T\d{2}(?::\d{2}){2}Z$/,
				'verify output string format');
  like($date, qr/^\d{4}(?:-\d{2}){2}T\d{2}(?::\d{2}){2}Z$/,
				'... also tested with string conversion');

  # epoch timestamp used:  1567901970  <==>  2019-09-08T00:19:30Z
  $date = WARC::Date->from_epoch(1567901970);

  isa_ok($date, 'WARC::Date',		'epoch timestamp as a WARC::Date');

  is($date->as_epoch, 1567901970,	'read value as epoch timestamp');
  is($date->as_string, '2019-09-08T00:19:30Z',
					'read value as string timestamp');

  cmp_ok($date, '==', 1567901970,	'read value as numeric conversion');
  cmp_ok($date, 'eq', '2019-09-08T00:19:30Z',
					'read value as string conversion');

  $date = WARC::Date->from_string('2019-09-08T00:19:30Z');

  isa_ok($date, 'WARC::Date',		'string timestamp as a WARC::Date');

  is($date->as_epoch, 1567901970,	'read value as epoch timestamp');
  is($date->as_string, '2019-09-08T00:19:30Z',
					'read value as string timestamp');

  cmp_ok($date, '==', 1567901970,	'read value as numeric conversion');
  cmp_ok($date, 'eq', '2019-09-08T00:19:30Z',
					'read value as string conversion');
}

note('*' x 60);

# WARC::Date values are never tainted
SKIP:
{
  skip "could not check taint mode", 4 unless defined $ENV{PATH};
  skip "perl not running in taint mode", 4 unless tainted $ENV{PATH};

  open IN, '<', File::Spec->catfile($Bin, 'WARC-Date.in')
    or BAIL_OUT "could not open input file: $!";
  my $tainted_epoch_timestamp = <IN>;
  my $tainted_string_timestamp = <IN>;
  close IN;

  BAIL_OUT "taint checks not behaving as expected (epoch)"
    unless tainted $tainted_epoch_timestamp;
  BAIL_OUT "taint checks not behaving as expected (string)"
    unless tainted $tainted_string_timestamp;

  BAIL_OUT "input data not as expected"
    unless ($tainted_epoch_timestamp =~ m/^[0-9]+$/
	    && $tainted_string_timestamp =~ m/^[-0-9]{10}T[:0-9]{8}Z$/);

  my $date_from_epoch = WARC::Date->from_epoch($tainted_epoch_timestamp);

  ok((not tainted $date_from_epoch->as_epoch),
     'epoch value from epoch date not tainted');
  ok((not tainted $date_from_epoch->as_string),
     'string value from epoch date not tainted');

  my $date_from_string = WARC::Date->from_string($tainted_string_timestamp);

  ok((not tainted $date_from_string->as_epoch),
     'epoch value from string date not tainted');
  ok((not tainted $date_from_string->as_string),
     'string value from string date not tainted');
}
