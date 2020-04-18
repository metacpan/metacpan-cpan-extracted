# Unit tests for WARC::Record::Replay module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests =>
     2	# Loading tests
  +  4	# Invalid registrations
  +  2	# Basic tests
  +  9;	# Autoloading tests

BEGIN { use_ok('WARC::Record::Replay')
	  or BAIL_OUT "WARC::Record::Replay failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record::Replay v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/ version v9999.*required--this is only version/,
     'WARC::Record::Replay version check')
}

use File::Spec;

my $AL_TestDir = File::Spec->catdir($Bin, 'replay_autoload');
my $HF_TestDir = File::Spec->catdir($Bin, 'heuristics_files');

note('*' x 60);

# Invalid registrations
{
  my $fail = 0;
  eval {&WARC::Record::Replay::register('bogus', sub {}); $fail = 1;};
  ok($fail == 0 && $@ =~ m/register invalid handler/,
     'croak registering bogus handler (1)');

  $fail = 0;
  eval {&WARC::Record::Replay::register(sub {0}, 'bogus'); $fail = 1;};
  ok($fail == 0 && $@ =~ m/register invalid handler/,
     'croak registering bogus handler (2)');

  is(scalar @WARC::Record::Replay::Handlers, 0,
     'empty handler list');
  WARC::Record::Replay::register sub {0}, sub {};
  is(scalar @WARC::Record::Replay::Handlers, 1,
     'empty handler registered');
}

note('*' x 60);

# Basic tests
sub check_handlers ($) {
  my $ob = shift;

  my @handlers = WARC::Record::Replay::find_handlers $ob;

  return map { $_->($ob) } @handlers;
}

{
  WARC::Record::Replay::register { $_ == 1 } sub { 1 };
  WARC::Record::Replay::register { $_ == 2 } sub { 2 };

  is_deeply([check_handlers 1], [1],	'find handlers for "1"');
  is_deeply([check_handlers 2], [2],	'find handlers for "2"');
}

# Autoloading tests
@WARC::Record::Replay::Handlers = ();

{
  package WARC::Record::_TestMock;

  sub field { $_[0]->{$_[1]} }
}

{
  local @INC = ($AL_TestDir, $HF_TestDir);
  @INC = map {m/^(.*)$/; $1} @INC; # untaint @INC

  BAIL_OUT 'unexpected state'
    if defined $WARC::Record::Replay::Test1::Loaded
      or defined $WARC::Record::Replay::Test2::Loaded;

  my $ob = bless { 'Content-Type' => 'test/error' }, 'WARC::Record::_TestMock';

  {
    my $fail = 0;
    eval {WARC::Record::Replay::find_handlers $ob; $fail = 1};
    ok($fail == 0
       && $@ =~ "loading bogus handler module",
       'error while loading handler propagates');
  }

  $ob = bless { 'Content-Type' => 'test/bogus' }, 'WARC::Record::_TestMock';

  is_deeply([check_handlers $ob], [],
		'find handlers for bogus test record');
  is($WARC::Record::Replay::Test1::Loaded, undef,
		'type 1 test handler not loaded');
  is($WARC::Record::Replay::Test2::Loaded, undef,
		'type 2 test handler not loaded');

  $ob = bless { 'Content-Type' => 'test/type-1' }, 'WARC::Record::_TestMock';

  is_deeply([check_handlers $ob], ['type-1'],
		'find handlers for type 1 test record');
  is($WARC::Record::Replay::Test1::Loaded, 1,
		'type 1 test handler autoloaded');
  is($WARC::Record::Replay::Test2::Loaded, undef,
		'type 2 test handler not loaded');

  $ob = bless { 'Content-Type' => 'test/type-2' }, 'WARC::Record::_TestMock';

  is_deeply([check_handlers $ob], ['type-2'],
		'find handlers for type 2 test record');
  is($WARC::Record::Replay::Test2::Loaded, 1,
		'type 2 test handler autoloaded');

}
