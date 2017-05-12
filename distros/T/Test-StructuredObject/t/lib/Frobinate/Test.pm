package Frobinate::Test;

# ABSTRACT: A dummy package that just returns a test object.

use strict;
use warnings;

use Test::More;
use Test::StructuredObject;
use namespace::autoclean;

sub testcode {
  return testsuite(
    step { note "This is a non-test"; },
    test { ok( 1, 'Ok Test' ) },
    testgroup(
      foo => ( test { ok( 1, 'Ok in sub test' ) }, step { die "Hurp testing" }, test { ok( 1, 'Post Hurp testing' ) } )
    )
  );
}

1;

