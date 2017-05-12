# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Hanako.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
#use Test::More;
BEGIN { use_ok('WWW::Hanako') };

#########################
#eval "use Test::Pod 1.00";
#plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
#all_pod_files_ok();

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $hanako = WWW::Hanako->new(area=>3, mst=>50810100);
ok($hanako);
ok($hanako->now());

