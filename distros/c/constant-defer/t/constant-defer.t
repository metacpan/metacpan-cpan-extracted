#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2013, 2015 Kevin Ryde

# This file is part of constant-defer.
#
# constant-defer is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# constant-defer is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with constant-defer.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use constant::defer;
use Test;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

plan tests => 49;

sub streq_array {
  my ($a1, $a2) = @_;
  while (@$a1 && @$a2) {
    unless ((! defined $a1->[0] && ! defined $a2->[0])
            || (defined $a1->[0]
                && defined $a2->[0]
                && $a1->[0] eq $a2->[0])) {
      return 0;
    }
    shift @$a1;
    shift @$a2;
  }
  return (@$a1 == @$a2);
}

#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 6;
  ok ($constant::defer::VERSION, $want_version, 'VERSION variable');
  ok (constant::defer->VERSION,  $want_version, 'VERSION class method');
  ok (eval { constant::defer->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { constant::defer->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# plain name

my $have_weaken;
my $skip_weaken;

{
  my $foo_runs = 0;
  use constant::defer FOO => sub { $foo_runs++; return 123 };

  my $orig_code;
  $orig_code = \&FOO;

  ok (FOO, 123, 'FOO first run');
  ok ($foo_runs, 1, 'FOO first runs code');

  ok (&$orig_code(), 123, 'FOO orig second run');
  ok ($foo_runs, 1, "FOO orig second doesn't run code");

  $have_weaken = eval { require Scalar::Util;
                        my $x = [ 'hello' ];
                        Scalar::Util::weaken($x);
                        if (defined $x) {
                          die "Oops, weakening didn't garbage collect";
                        }
                        1
                      };
  if (! $have_weaken) {
    MyTestHelpers::diag ("Scalar::Util::weaken() not available -- ",$@);
    $skip_weaken = 'due to Scalar::Util::weaken() not available';
  }

  {
    if ($have_weaken) {
      Scalar::Util::weaken ($orig_code);
    }
    skip ($skip_weaken,
          ! defined $orig_code,
          1,
          'orig FOO code garbage collected');

    $foo_runs = 0;
    ok (FOO, 123, 'FOO second run');
    ok ($foo_runs, 0, "FOO second doesn't run code");
  }
}

#------------------------------------------------------------------------------
# fully qualified name

{
  my $runs = 0;
  use constant::defer 'Some::Non::Package::Place::func' => sub {
    $runs = 1; return 'xyz' };

  ok (Some::Non::Package::Place::func(), 'xyz',
      'explicit package first run');
  ok ($runs, 1,
      'explicit package first run runs code');

  $runs = 0;
  ok (Some::Non::Package::Place::func(), 'xyz',
      'explicit package second run');
  ok ($runs, 0,
      'explicit package second run doesn\'t run code');
}

#------------------------------------------------------------------------------
# array value

{
  my $runs = 0;
  use constant::defer THREE => sub { $runs = 1;
                                     return ('a','b','c') };

  ok (streq_array ([ THREE() ],
                   [ 'a', 'b', 'c' ]),
      1,
      'THREE return values first run');
  ok ($runs, 1,
      'THREE return values first run runs code');

  $runs = 0;
  ok (streq_array([ THREE() ],
                  [ 'a', 'b', 'c' ]),
      1,
      'THREE return values second run');
  ok ($runs, 0,
      'THREE return values second run doesn\'t run code');
}

{
  my $runs = 0;
  use constant::defer THREE_SCALAR => sub { $runs = 1;
                                            return ('a','b','c') };

  my $got = THREE_SCALAR();
  ok ($got, 3,
      'three values in scalar context return values first run');
  ok ($runs, 1,
      'three values in scalar context return values first run runs code');

  $runs = 0;
  $got = THREE_SCALAR();
  ok ($got, 3,
      'three values in scalar context return values second run');
  ok ($runs, 0,
      'three values in scalar context return values second run doesn\'t run code');
}

#------------------------------------------------------------------------------
# multiple names

{
  use constant::defer
    PAIR_ONE => sub { 123 },
    PAIR_TWO => sub { 456 };
  ok (PAIR_ONE, 123, 'PAIR_ONE');
  ok (PAIR_TWO, 456, 'PAIR_TWO');
}
{
  use constant::defer { HASH_ONE => sub { 123 },
                        HASH_TWO => sub { 456 } };
  ok (HASH_ONE, 123, 'HASH_ONE');
  ok (HASH_TWO, 456, 'HASH_TWO');
}
{
  use constant::defer SHASH_ONE => sub { 123 },
                      { SHASH_TWO => sub { 456 },
                        SHASH_THREE => sub { 789 } };
  ok (SHASH_ONE, 123, 'SHASH_ONE');
  ok (SHASH_TWO, 456, 'SHASH_TWO');
  ok (SHASH_THREE, 789, 'SHASH_THREE');
}

#------------------------------------------------------------------------------
# with can()

{
  my $runs = 0;
  package MyTestCan;
  use constant::defer CANNED => sub { $runs++; return 'foo' };

  package main;
  my $func = MyTestCan->can('CANNED');

  my $got = &$func();
  ok ($got, 'foo', 'through can() - result');
  ok ($runs, 1,    'through can() - run once');

  $got = &$func();
  ok ($got, 'foo', 'through can() - 2nd result');
  ok ($runs, 1,    'through can() - 2nd still run once');
}

#------------------------------------------------------------------------------
# with Exporter import()

{
  my $runs = 0;

  package MyTestImport;
  use vars qw(@ISA @EXPORT);
  use constant::defer TEST_IMPORT_FOO => sub { $runs++; return 'foo' };
  require Exporter;
  @ISA = ('Exporter');
  @EXPORT = ('TEST_IMPORT_FOO');

  package main;
  MyTestImport->import;

  my $got = TEST_IMPORT_FOO();
  ok ($got, 'foo', 'through import - result');
  ok ($runs, 1,    'through import - run once');

  $got = TEST_IMPORT_FOO();
  ok ($got, 'foo', 'through import - 2nd result');
  ok ($runs, 1,    'through import - 2nd still run once');
}

#------------------------------------------------------------------------------
# gc of supplied $subr after it's been called

{
  my $subr;
  BEGIN {
    # crib: anon sub must refer to a lexical or isn't gc'ed, at least in 5.6.0
    my $lexical_var = 'gc me';
    $subr = sub { return $lexical_var };
  }
  use constant::defer WEAKEN_CONST => $subr;

  # including when the can() first func is retained
  # my $cancode = main->can('WEAKEN_CONST');

  my @got = WEAKEN_CONST();
  ok (streq_array (\@got,
                   ['gc me']),
      1,
      'WEAKEN_CONST - result');

  if ($have_weaken) {
    Scalar::Util::weaken ($subr);
  }
  skip ($skip_weaken,
        ! defined $subr,
        1,
        'WEAKEN_CONST - subr now undef');
}

{
  my ($objref, $subr);
  my $runs = 0;
  BEGIN {
    my %obj = (foo => 'bar');
    $subr = sub { $runs++; return %obj };
    $objref = \%obj;
  }
  use constant::defer WEAKEN_OBJRET => $subr;

  # including when the can() first func is retained
  # my $cancode = main->can('WEAKEN_OBJRET');

  my @got = WEAKEN_OBJRET();
  ok (streq_array (\@got,
                   ['foo','bar']),
      1,
      'WEAKEN_OBJRET - result');
  ok ($runs, 1, 'WEAKEN_OBJRET - run once');

  if ($have_weaken) {
    Scalar::Util::weaken ($subr);
    Scalar::Util::weaken ($objref);
  }
  skip ($skip_weaken,
        ! defined $subr,
        1,
        'WEAKEN_OBJRET - subr now undef');
  skip ($skip_weaken,
        ! defined $objref,
        1,
        'WEAKEN_OBJRET - objref now undef');
}

#------------------------------------------------------------------------------
# gc of can() after called

{
  use constant::defer CAN_GC => sub { return 'gc me' };
  my $cancode = main->can('CAN_GC');

  my @got = CAN_GC();
  ok (streq_array (\@got,
                   ['gc me']),
      1,
      'CAN_GC - result');

  if ($have_weaken) {
    Scalar::Util::weaken ($cancode);
  }
  skip ($skip_weaken,
        ! defined $cancode,
        1,
        'CAN_GC - can() coderef now undef');
}

#------------------------------------------------------------------------------
# gc of initial definition after called

{
  use constant::defer INITIAL_GC => sub { return 'gc me' };
  my $coderef = \&INITIAL_GC;

  my @got = INITIAL_GC();
  ok (streq_array (\@got,
                   ['gc me']),
      1,
      'INITIAL_GC - result');

  if ($have_weaken) {
    Scalar::Util::weaken ($coderef);
  }
  skip ($skip_weaken,
        ! defined $coderef,
        1,
        'INITIAL_GC - saved initial now undef');
}

#------------------------------------------------------------------------------
# gc of runner helper after redefine

{
  use constant::defer RUNNER_GC => sub { return 'gc me' };
  my $runner;
  BEGIN {
    $runner = $constant::defer::DEBUG_LAST_RUNNER;
    undef $constant::defer::DEBUG_LAST_RUNNER;
  }
  if (! $runner) {
    MyTestHelpers::diag ("DEBUG_LAST_RUNNER not enabled in defer.pm");
  }

  do {
    local $^W = 0; # no warnings 'redefine';
    eval '*RUNNER_GC = sub () { "new value" }; 1';
  } or die "Oops, eval error: $@";

  if ($have_weaken) {
    Scalar::Util::weaken ($runner);
  }
  skip ($skip_weaken,
        ! defined $runner,
        1,
        'RUNNER_GC - now undef');
  if ($runner) {
    require Devel::FindRef;
    MyTestHelpers::diag (Devel::FindRef::track($runner));
  }
}

exit 0;
