#!/usr/bin/perl -T
use 5.006;
use strict;
use warnings;
use Test::Tester tests => 3;
use Test::More;
use Test::Version version_ok => {
  multiple => 1,
  consistent => 1,
  ignore_unindexable => 0,
};

subtest 'multiple, good' => sub {
  my $ret;
  check_test(
    sub {
      $ret = version_ok( 'corpus/multiple/Foo.pm' );
    },
    {
      ok => 1,
      name => q[check version in 'corpus/multiple/Foo.pm'],
      diag => '',
    },
    'version ok'
  );

  ok $ret, "version_ok() returned true on pass";

};

subtest 'multiple, missing' => sub {
  my $ret;
  check_test(
    sub {
      $ret = version_ok( 'corpus/multiple-missing/Foo.pm' );
    },
    {
      ok => 0,
      name => q[check version in 'corpus/multiple-missing/Foo.pm'],
      diag => 'No version was found in \'corpus/multiple-missing/Foo.pm\' (Foo::Bar).',
    },
    'version ok'
  );

  ok !$ret, "version_ok() returned false on fail";

};

subtest 'multiple, inconsistent' => sub {
  my $ret;
  check_test(
    sub {
      $ret = version_ok( 'corpus/multiple-inconsistent/Foo.pm' );
    },
    {
      ok => 0,
      name => q[check version in 'corpus/multiple-inconsistent/Foo.pm'],
      diag => 'The versions found in \'corpus/multiple-inconsistent/Foo.pm\' are inconsistent.',
    },
    'version ok'
  );

  ok !$ret, "version_ok() returned false on fail";

};
