# Unit tests for WARC::Index module				# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use Test::More tests => 2 + 3 + (4 + 6) + (3 + 9 + 1);

BEGIN { $INC{'WARC/Index/Builder.pm'} = 'mocked in test driver' }

{ package WARC::Index::Builder }

BEGIN { use_ok('WARC::Index')
	  or BAIL_OUT "WARC::Index failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Index v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Index version check')
}

{
  my $fail = 0;
  eval { my $index = attach WARC::Index (); $fail = 1 };
  ok($fail == 0 && $@ =~ m/abstract base class/,
     'attaching base class dies');

  {
    my $index = bless {}, 'WARC::Index'; # make a fake index object

    $fail = 0;
    eval { $index->searchable('bogus'); $fail = 1 };
    ok($fail == 0 && $@ =~ m/abstract base class/,
       'checking key in base class dies');

    $fail = 0;
    eval { $index->search(bogus => 1); $fail = 1 };
    ok($fail == 0 && $@ =~ m/abstract base class/,
       'search method in base class dies');
  }
}

note('*' x 60);

# Index registration tests
{
  package WARC::Index::_TestMock::Bogus;

  use Test::More;

  {
    my $fail = 0;
    eval {WARC::Index::register(filename => qr/bogus/); $fail = 1;};
    ok($fail == 0 && $@ =~ m/must subclass WARC::Index/,
       'registering bogus index module dies');
  }
}
{
  package WARC::Index::_TestMock::I1;

  use Test::More;

  our @ISA = qw(WARC::Index);

  {
    my $fail = 0;
    eval {WARC::Index::register(); $fail = 1;};
    ok($fail == 0 && $@ =~ m/must.*filename pattern/,
       'invalid index registration dies (1)');

    my $warn_count = 0;
    local $SIG{__WARN__} = sub {$warn_count++};
    $fail = 0;
    eval {WARC::Index::register(qr/[.]idx$/); $fail = 1;};
    ok($fail == 0 && $@ =~ m/must.*filename pattern/,
       'invalid index registration dies (2)');
    is($warn_count, 1,	'one warning produced during invalid call');
  }

  WARC::Index::register(filename => qr/[.]idx1$/);
}
{
  package WARC::Index::_TestMock::I2;

  our @ISA = qw(WARC::Index);

  WARC::Index::register(filename => qr/[.]idx2$/);
  WARC::Index::register(filename => qr/[.]idx2a$/);
  WARC::Index::register(filename => qr/[.]idx2b$/);
}
{
  package WARC::Index::_TestMock::IXa;

  our @ISA = qw(WARC::Index);

  WARC::Index::register(filename => qr/[.]idx.a$/);
}

is(WARC::Index::find_handler('test.idx1'), 'WARC::Index::_TestMock::I1',
   'find_handler for "test.idx1" finds I1');
is(WARC::Index::find_handler('test.idx2'), 'WARC::Index::_TestMock::I2',
   'find_handler for "test.idx2" finds I2');
like(WARC::Index::find_handler('test.idx2a'),
     qr/WARC::Index::_TestMock::I(?:2|Xa)/,
     'find_handler for "test.idx2a" finds I2 or IXa');
is(WARC::Index::find_handler('test.idx2b'), 'WARC::Index::_TestMock::I2',
   'find_handler for "test.idx2b" finds I2');
is(WARC::Index::find_handler('test.idx3a'), 'WARC::Index::_TestMock::IXa',
   'find_handler for "test.idx3a" finds IXa');
ok((not defined WARC::Index::find_handler('test.idx')),
   'find_handler returns undef for "test.idx"');

# Index building tests
{
  package WARC::Index::_TestMock::I1::Builder;

  our @ISA = qw(WARC::Index::Builder);

  our $__lastob = undef;
  sub _new { my $class = shift; $__lastob = bless {c => [@_]}, $class }
  sub add { my $self = shift; $self->{a} = [@_] }
}

{
  my $fail = 0; my $builder = undef;
  eval { $builder = build WARC::Index::_TestMock::I1 (); $fail = 1};
  ok(!defined $builder && $fail == 0 && $@ =~ m/no arguments/,
     'reject bogus index build call with no arguments') or diag $@;

  $fail = 0; $builder = undef;
  eval { $builder = build WARC::Index::_TestMock::I1 ('from'); $fail = 1};
  ok(!defined $builder && $fail == 0 && $@ =~ m/empty list/,
     'reject bogus index build call with "from" defined but empty') or diag $@;

  my $fakeindex = bless {}, 'WARC::Index';
  $fail = 0; $builder = undef;
  eval { $builder = $fakeindex->build (from => 'file'); $fail = 1};
  ok(!defined $builder && $fail == 0 && $@ =~ m/class method/,
     'reject calling "build" method on an index object') or diag $@;
}

{
  my @builder = build WARC::Index::_TestMock::I1
    (from => [qw/foo bar baz quux/], foo => 1, bar => 2);
  is(scalar @builder, 0,
     'no value returned from "build" with "from" option (1)');
  is_deeply($WARC::Index::_TestMock::I1::Builder::__lastob->{c},
	    [foo => 1, bar => 2],
	    'index-specific construction options passsed (1)');
  is_deeply($WARC::Index::_TestMock::I1::Builder::__lastob->{a},
	    [qw/foo bar baz quux/],
	    'index sources passed to "add" method (1)');

  @builder = build WARC::Index::_TestMock::I1
    (bar => 4, foo => 3, from => qw/foo baz bar quux/);
  is(scalar @builder, 0,
     'no value returned from "build" with "from" option (2)');
  is_deeply($WARC::Index::_TestMock::I1::Builder::__lastob->{c},
	    [bar => 4, foo => 3],
	    'index-specific construction options passsed (2)');
  is_deeply($WARC::Index::_TestMock::I1::Builder::__lastob->{a},
	    [qw/foo baz bar quux/],
	    'index sources passed to "add" method (2)');

  my $builder = build WARC::Index::_TestMock::I1 (foo => 5, bar => 6);
  isa_ok($builder, 'WARC::Index::Builder',
	 'index builder returned when "from" option not given');
  is_deeply($builder->{c},
	    [foo => 5, bar => 6],
	    'index-specific construction options passsed (3)');
  ok(!exists $builder->{a},
     'index builder "add" method not called when "from" option not given');

  my $fail = 0; $builder = undef;
  eval { $builder = build WARC::Index::_TestMock::I2 (foo => 7, bar => 8);
	 $fail = 1 };
  ok($fail == 0 && $@ =~ m/_TestMock[^I]*I2[^B]*Builder\.pm/,
     'failure to load index builder class propagates') or diag $@;
}
