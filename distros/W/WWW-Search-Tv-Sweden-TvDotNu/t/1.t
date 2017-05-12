# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use strict;

BEGIN { use_ok('WWW::Search::Tv::Sweden::TvDotNu') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tv = WWW::Search::Tv::Sweden::TvDotNu->new();
my $db = $tv->get_today();

foreach my $entry ($db->between(16, 0, 21, 0)->entries) {
  $tv->get_full_entry($entry);
}

ok(2);