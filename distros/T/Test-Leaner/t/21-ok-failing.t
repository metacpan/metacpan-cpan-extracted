#!perl -T

use strict;
use warnings;

use Test::More;

BEGIN { delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE} }

use Test::Leaner ();

use lib 't/lib';
use Test::Leaner::TestHelper;

my $buf;
capture_to_buffer $buf
                  or plan skip_all =>'perl 5.8 required to test ok() failing';

plan tests => 3 * 5;

reset_buffer {
 local $@;
 my $ret = eval { Test::Leaner::ok(0) };
 is $@,    '',           'ok(0) does not croak';
 ok !$ret,               'ok(0) returns false';
 is $buf,  "not ok 1\n", 'ok(0) produces the correct TAP code';
};

reset_buffer {
 local $@;
 my $ret = eval { Test::Leaner::ok(undef) };
 is $@,    '',           'ok(undef) does not croak';
 ok !$ret,               'ok(undef) returns false';
 is $buf,  "not ok 2\n", 'ok(undef) produces the correct TAP code';
};

reset_buffer {
 local $@;
 my $ret = eval { Test::Leaner::ok(!1) };
 is $@,    '',           'ok(false) does not croak';
 ok !$ret,               'ok(false) returns false';
 is $buf,  "not ok 3\n", 'ok(false) produces the correct TAP code';
};

reset_buffer {
 local $@;
 my $ret = eval { Test::Leaner::ok(0, 'this is a comment') };
 is $@,    '', 'ok(0, "comment") does not croak';
 ok !$ret,     'ok(0, "comment") returns false';
 is $buf,  "not ok 4 - this is a comment\n",
               'ok(0, "comment") produces the correct TAP code';
};

{
 package Test::Leaner::TestOverload::AlwaysFalse;

 use overload (
  'bool' => sub { !1 },
  '""'   => sub { 'true' },
 );

 sub new { bless { }, shift }
}

my $z = Test::Leaner::TestOverload::AlwaysFalse->new;

reset_buffer {
 local $@;
 my $ret = eval { Test::Leaner::ok($z) };
 is $@,    '',           'ok($overloaded_false) does not croak';
 ok !$ret,               'ok($overloaded_false) returns false';
 is $buf,  "not ok 5\n", 'ok($overloaded_false) produces the correct TAP code';
};

