#!perl

## in a separate test file

use strict;
use warnings;

use Test::More;
BEGIN {
  $] >= 5.010 or plan skip_all => "Test::Kwalitee requires perl 5.10 (at least on AUTHOR's machine ^^)";
  plan skip_all => 'Set AUTHOR_TESTING environmental variable to test this.' unless $ENV{AUTHOR_TESTING};
}
use Test::Kwalitee 'kwalitee_ok';

kwalitee_ok();

done_testing;
