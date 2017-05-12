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
use ex::lib::zip 'two.zip';

# We will need to skip a directory and a file to get to Q.pm
use Q;
ok (&Q::qsub, "This is Q");
# We ought to resume the linear search after Q.pm
use Self;
ok (&Self::self, "This is the self loaded function", "SelfLoader didn't work");
# Data.pm should come from the hash
use Data;
ok (&Data::line, "Dromedary", "Can't read 1st camel from <DATA> filehandle");
ok (&Data::eof, '', "It's supposed *not* to be eof here");
ok (&Data::line, "Bactrian", "Can't read 2nd camel from <DATA> filehandle");
ok (&Data::eof, 1, "It's supposed to be eof here");
