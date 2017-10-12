use strict;
use warnings;

use Test::More tests => 1;
 
BEGIN {
   use_ok('Vlc::Engine') or BAIL_OUT("Couldn't load $_");
}

