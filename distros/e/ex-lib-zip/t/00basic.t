#! perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test qw (:DEFAULT $ntest);
BEGIN { plan tests => 5 };
use ex::lib::zip;
BEGIN {
  ok(1); # If we made it this far, we're ok.
}
#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

BEGIN {
  chdir 't' if -d 't';
}
use ex::lib::zip 'zero.zip';
BEGIN {
  ok (2); # Didn't blow up :-)
}
use ok (3);
use ok (4);
$ntest+=2;
ok (5); # Still didn't blow up :-)
