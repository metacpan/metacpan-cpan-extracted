# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Umlmgr.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Umlmgr') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
    my $mgr = Umlmgr->new(config => 'tdata/umlmgr.cfg');
    isa_ok($mgr, 'Umlmgr');
    ok(eq_set(
            [ $mgr->list_machines_config ],
            [ qw/test/ ],
            "can return list of vm"
    ));
    isa_ok($mgr->get_machine('test'), 'Umlmgr::Uml');
}
