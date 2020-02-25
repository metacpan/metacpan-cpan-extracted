# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl credsman.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More tests => 7;
use ExtUtils::testlib;
BEGIN { use_ok('credsman')};
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub testing_prototype{
    my $arg = shift;
    note ('Simulate Function');
    ok $arg->{user} eq 'Pepe', "Passing User     : $arg->{user}";
    ok $arg->{password} eq 'PepePass', "Passing Password : $arg->{password}";
    return 0;
}


my $credsname = credsman::work_name('credsman','Test');
ok $credsname eq '*[credsman]~[Test]*', 'Create Test Target Name';
ok !credsman::SaveCredentials($credsname, 'Pepe','PepePass'), 'Store User and Password';
ok !credsman::login( program  => "credsman", 
       target   => "Test",
       subref   => \&testing_prototype,
       debug    => 0,
), 'Credsman Login';
ok credsman::RemoveCredentials($credsname), 'Remove Test Credentials';
done_testing;