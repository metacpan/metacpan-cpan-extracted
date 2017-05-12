#!perl -T

use strict;
use warnings;

use Test::More;

our $status;
BEGIN {
 *CORE::GLOBAL::exit = *CORE::GLOBAL::exit = sub {
  my $caller = caller;
  if ($caller eq 'Test::Leaner') {
   $status = $_[0] || 0;
  } else {
   CORE::exit $_[0];
  }
 };

 delete $ENV{PERL_TEST_LEANER_USES_TEST_MORE};
}

use Test::Leaner ();

use lib 't/lib';
use Test::Leaner::TestHelper;

my $buf = '';
capture_to_buffer $buf
                  or plan skip_all => 'perl 5.8 required to test BAIL_OUT()';


plan tests => 6;

reset_buffer {
 local ($@, $status);
 eval { Test::Leaner::BAIL_OUT() };
 is $@,      '',            'BAIL_OUT() does not croak';
 is $buf,    "Bail out!\n", 'BAIL_OUT() produces the correct TAP code';
 is $status, 255,           'BAIL_OUT() exits with the correct status';
};

reset_buffer {
 local ($@, $status);
 eval { Test::Leaner::BAIL_OUT('this is a comment') };
 is $@,      '',  'BAIL_OUT("comment") does not croak';
 is $buf,    "Bail out!  this is a comment\n",
                  'BAIL_OUT("comment") produces the correct TAP code';
 is $status, 255, 'BAIL_OUT("comment") exits with the correct status';
};
