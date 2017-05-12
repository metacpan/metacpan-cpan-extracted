use strict;
use warnings;

use lib 't/lib';

use Test::More;

BEGIN {
    plan skip_all => 'tests require Test::Class to run'
      unless eval "use Test::Class; 1";
}

use My::Test::Class::Load 't/lib';
