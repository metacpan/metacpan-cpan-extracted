use strict;
use warnings;

use Test::More;
use Devel::StrictMode;

BEGIN {
  plan skip_all => 'these tests are for release candidate testing'
    unless STRICT;
} 
use Test::Kwalitee 'kwalitee_ok';
kwalitee_ok();

done_testing;
