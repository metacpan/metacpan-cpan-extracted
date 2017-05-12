# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Weather-TW.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use utf8;
use lib 'lib';
BEGIN { 
  use_ok('Weather::TW');
  new_ok 'Weather::TW';
};

