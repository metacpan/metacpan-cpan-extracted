#!perl -T

use strict;
use warnings;

use Test::More;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner ();

use lib 't/lib';
use Test::Leaner::TestHelper;

my $buf = '';
capture_to_buffer $buf or plan skip_all => 'perl 5.8 required to test pass()';

plan tests => 4;

reset_buffer {
 local $@;
 eval { Test::Leaner::pass() };
 is $@,   '',       'pass() does not croak';
 is $buf, "ok 1\n", 'pass() produces the correct TAP code';
};

reset_buffer {
 local $@;
 eval { Test::Leaner::pass('this is a comment') };
 is $@,   '', 'pass("comment") does not croak';
 is $buf, "ok 2 - this is a comment\n",
              'pass("comment") produces the correct TAP code';
};
