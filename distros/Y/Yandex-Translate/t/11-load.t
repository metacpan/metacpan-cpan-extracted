use strict;
use warnings;

use Test::More tests => 1;
 
BEGIN {
   use_ok('Yandex::Translate') or BAIL_OUT("Couldn't load $_");
}

