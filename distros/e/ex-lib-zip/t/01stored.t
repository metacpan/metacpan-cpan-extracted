#! perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test qw (:DEFAULT $ntest);
BEGIN { plan tests => 3 };
use ex::lib::zip;

BEGIN {
  chdir 't' if -d 't';
}
use ex::lib::zip 'one.zip';
use ok (1);
use ok (2);
$ntest+=2;
ok (3);
