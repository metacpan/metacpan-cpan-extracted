#! perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test qw (:DEFAULT $ntest);
BEGIN { plan tests => 6 };
use ex::lib::zip;

BEGIN {
  chdir 't' if -d 't';
}
use ex::lib::zip 'three.zip';

use Auto qw (body auto1);
ok (body, "I'm in the body");
ok (auto1, "first", "First autoload failed");
ok (&Auto::auto2, "second", "Second autoload failed");

use Nested::Quite::Deep qw (spam spanish_inquisition panic penguin);
ok (spam, "Bloody Vikings", "spam, spam, spam, spam");
ok (panic, "Burma", "Why did you say Burma? I panicked");
ok (join (",", spanish_inquisition), qr/^Fear/);

