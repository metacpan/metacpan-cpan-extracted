# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Mixi.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('WWW::Mixi') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use WWW::Mixi;
my $mixi = WWW::Mixi->new('dummy@address', 'dummy_password');

ok($mixi, 'Construct mixi object.');
