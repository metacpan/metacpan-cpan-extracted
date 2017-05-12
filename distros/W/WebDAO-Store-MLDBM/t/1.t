# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests=>10;
#use Test::More (no_plan);
use File::Temp qw/ tempdir /;
use Data::Dumper;
use strict;
BEGIN { 
    use_ok('WebDAO');
    use_ok('WebDAO::Store::Abstract');
    use_ok('WebDAO::Store::MLDBM'); 
    use_ok('WebDAO::Container'); 
    use_ok('WebDAO::Engine'); 
    use_ok('WebDAO::SessionSH');

}

sub test_storage {
    my $object = shift;
    ok( $object, "Create Store " . ref($object) );
    my $ref = { test => 'test' };
    my $id = "ID";
    $object->store( $id, $ref );
    ok( $object->load($id)->{test} eq $ref->{test}, "Test load" );
}
my $dir = tempdir( CLEANUP => 1 );
my $store_ml = new WebDAO::Store::MLDBM:: path => $dir;
test_storage($store_ml);
my $store_ab = new WebDAO::Store::Abstract::;
ok( $store_ab, "Create abstract Store" );
my $session = new WebDAO::SessionSH::;
ok( $session, "Create abstract Store" );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

