#!perl

use strict;
use warnings;

use Test::More;
BEGIN {
  $] >= 5.010 or plan skip_all => "CPAN::Changes requires perl 5.10";
  plan skip_all => 'Set AUTHOR_TESTING environmental variable to test this.' unless $ENV{AUTHOR_TESTING};
}
use Test::CPAN::Changes;

changes_ok();
