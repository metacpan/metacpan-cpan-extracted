# Unit tests for WARC::Record::Sponge module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests
  => 2	# loading tests
  + 23	# basic tests
  +  6	# block access tests
  +  6	# digest calculation tests
  +  1;	# leak check

BEGIN { use_ok('WARC::Record::Sponge')
	  or BAIL_OUT "WARC::Record::Sponge failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record::Sponge v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/ version v9999.*required--this is only version/,
     'WARC::Record::Sponge version check')
}

use Digest::SHA;
use Errno qw/EBADF/;
use Fcntl qw/SEEK_SET/;
{
  # untaint value -- do not do in production!
  ($WARC::Record::Sponge::TmpDir) = $Bin =~ m/^(.*)$/;
}

note('*' x 60);

# Basic tests
{
  my $sponge = new WARC::Record::Sponge (type => 'metadata');

  # first empty write is for code coverage
  syswrite $sponge, "";
  ok((defined fileno $sponge),		'fileno returns a defined value');
  syswrite $sponge, "foo\n";
  {local $, = "a"; print $sponge "b","r\n";}
  printf $sponge '%s%s', 'baz', "\n";
  is(seek($sponge, 0, SEEK_SET), undef,	'seek not allowed during "soak" phase');
  $sponge->readback;	# end write

  my $buffer = '';
  is($sponge->content_length, 12,	'check length of stored data');
  is(sysread($sponge, $buffer, 1<<10), 12, 'readback initial data (length)');
  is($buffer, "foo\nbar\nbaz\n",	'readback initial data (contents)');
  is(seek($sponge, 4, SEEK_SET), 4,	'seek works during "squeeze" phase');
  is(sysread($sponge, $buffer, 1<<10), 8, 'reread initial tail (length)');
  is($buffer, "bar\nbaz\n",		'reread initial tail (contents)');
  $sponge->reset;	# end read and reset

  # binmode is called here for code coverage
  binmode $sponge, ':raw';
  # split write is for code coverage
  syswrite $sponge, "foobar\n", 3;
  ok((eof $sponge),			'at eof during "soak" phase');
  $! = 0;
  is(sysread($sponge, $buffer, 0), undef,
     'read not allowed during "soak" phase');
  ok($!{EBADF},
     'read attempt during "soak" phase sets proper error');
  $! = 0;
  syswrite $sponge, "foobar\n", 4, 3;
  close $sponge;	# end write

  $buffer = '';
  is($sponge->content_length, 7,	'check length of stored data');
  ok((not eof $sponge),			'not at eof before read');
  is(sysread($sponge, $buffer, 1<<10), 7, 'readback shorter data (length)');
  is($buffer, "foobar\n",		'readback shorter data (contents)');
  ok((eof $sponge),			'at eof after read');
  is(sysread($sponge, $buffer, 1<<10), 0, 'read at eof returns nothing');
  $! = 0;
  is(syswrite($sponge, "test"), undef,
     'write not allowed during "squeeze" phase');
  ok($!{EBADF},
     'write attempt during "squeeze" phase sets proper error');
  $! = 0;
  # split read is for code coverage
  ok(seek($sponge, 0, SEEK_SET),	'seek back for reread');
  $buffer = undef;
  is(sysread($sponge, $buffer, 3), 3,	'reread first part (length)');
  is(sysread($sponge, $buffer, 4, 4), 4, 'reread second part (length)');
  is($buffer, "foo\0bar\n",		'readback with split read (contents)');
  close $sponge;	# end read and reset
}

note('*' x 60);

# Block access tests
{
  my $sponge = new WARC::Record::Sponge qw/type metadata/;

  print $sponge "foobar\n";
  is($sponge->block, "foobar\n",	'early readback as full block');
  print $sponge "bazquux\n";
  $sponge->readback;

  my $buffer = undef;
  is(sysread($sponge, $buffer, 1<<10), 15, 'readback full (length)');
  is($buffer, "foobar\nbazquux\n",	'readback full (contents)');

  {
    my $fail = 0;
    eval {$sponge->block("bogus"); $fail = 1};
    ok($fail == 0 && $@ =~ m/replace block.*squeeze/,
       'reject attempt to replace block during "squeeze" phase');
  }

  $sponge->reset;
  print $sponge "foo\n";
  $sponge->block("test\n");

  $sponge->readback; $buffer = undef;
  is(sysread($sponge, $buffer, 1<<10), 5, 'readback block (length)');
  is($buffer, "test\n",			'readback block (contents)');
}

note('*' x 60);

# Digest calculation tests
{
  my $sponge = new WARC::Record::Sponge qw/type metadata/;

  $sponge->begin_digest(block => sha1 => new Digest::SHA ('sha1'));
  print $sponge "test header\n\n";
  is($sponge->get_digest('block'), 'sha1:WFEXM6FITTL7WEJ2C6BBQTSW7J4PRTCP',
     'compute proper incremental block digest during "soak" phase');
  $sponge->begin_digest(payload => sha1 => new Digest::SHA ('sha1'));
  print $sponge "test payload\n";

  $sponge->readback;
  is($sponge->get_digest('block'), 'sha1:4N5X3KH62IPAWSQDZMIJPAI65C22IQNZ',
     'compute proper block digest');
  is($sponge->get_digest('payload'), 'sha1:WPF26XJIOEV6NTTAPIA3B2P62W7COMGV',
     'compute proper payload digest');
  is($sponge->get_digest('bogus'), undef,
     'extra "bogus" digest is undefined');

  my $buffer = undef;
  is(sysread($sponge, $buffer, 1<<10), 26,
     'readback with digests (length)');
  is($buffer, "test header\n\ntest payload\n",
     'readback with digests (contents)');
}

note('*' x 60);

# Verify construction/destruction balance
is($WARC::Record::Sponge::_total_destroyed,
   $WARC::Record::Sponge::_total_constructed,
   'all WARC::Record::Sponge objects released');
