# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Umlmgr.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Umlmgr::Uml') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
my $umlmachine = Umlmgr::Uml->new('noexists');
ok(! defined($umlmachine), "Bad config return undef")
}

{
my $umlmachine = Umlmgr::Uml->new('tdata/test.uml');
isa_ok($umlmachine, 'Umlmgr::Uml');
ok(eq_set(
    [ $umlmachine->build_uml_cmd ],
    [
    'linux', 'ubda=/tmp/disk', 'eth0=daemon,', 'umid=test',
    'con0=fd:0,fd:1', 'con=pts'
    ],
));

}
