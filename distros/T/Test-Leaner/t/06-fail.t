#!perl -T

use strict;
use warnings;

use Test::More;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner ();

use lib 't/lib';
use Test::Leaner::TestHelper;

my $buf = '';
capture_to_buffer $buf or plan skip_all => 'perl 5.8 required to test fail()';


plan tests => 4;

reset_buffer {
 local $@;
 eval { Test::Leaner::fail() };
 is $@,   '',           'fail() does not croak';
 is $buf, "not ok 1\n", 'fail() produces the correct TAP code';
};

reset_buffer {
 local $@;
 eval { Test::Leaner::fail('this is a comment') };
 is $@,   '', 'fail("comment") does not croak';
 is $buf, "not ok 2 - this is a comment\n",
              'fail("comment") produces the correct TAP code';
};
