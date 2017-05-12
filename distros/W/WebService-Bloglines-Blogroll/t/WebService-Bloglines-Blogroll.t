# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WebService-Bloglines-Blogroll.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('WebService::Bloglines::Blogroll') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
# 
# TODO: add appropriatetests!
#

my $br = new WebService::Bloglines::Blogroll(user_name => 'stepanov');
isa_ok($br, 'WebService::Bloglines::Blogroll');

$br->retrieve_blogroll();
my $items = $br->get_blogroll_hash('Perl');
ok(scalar(@$items) == 4, 'Folder "Perl" is Ok');

$br->get_blogroll_as_html();

my $folders = $br->get_list_folders();
ok(scalar(@$folders) == 6, 'Number of Folders is OK');
