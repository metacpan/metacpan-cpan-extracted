#! perl

use strict;
use warnings;

use Test::More;
BEGIN {
  $] >= 5.010 or plan skip_all => "Test::Pod::Spelling::CommonMistakes requires perl 5.10";
  plan skip_all => 'Set AUTHOR_TESTING environmental variable to test this.' unless $ENV{AUTHOR_TESTING};
}
use Test::Pod::Spelling::CommonMistakes qw(all_pod_files_ok);

all_pod_files_ok();

1;
