use Test::More;

use strict;
use warnings;
BEGIN {
   plan skip_all => 'these tests are for release candidate testing'
      unless $ENV{RELEASE_TESTING};
}

use Test::Kwalitee::Extra qw(:optional);

done_testing;
