use Test::Most;



package MyRole;

use Role::Tiny;

around something => sub {
    my $orig = shift;
    my $meth = shift;
    
    return $orig->( $meth => @_ )
};



package MyClassWithRole;

use Role::Tiny::With;

with 'MyRole';

sub something { ... };



package MyClassNotImplemented;



package main;

use Test::Interface;

use Test::Builder::Tester;

test_out( "ok 1 - MyClassWithRole does interface MyRole" );

interface_ok( 'MyClassWithRole', 'MyRole' );


test_test "Test PASS when 'interface_ok' - ok";


test_out( "not ok 1 - MyClassNotImplemented does interface MyRole" );
test_diag( "MyClassNotImplemented does not implement the MyRole interface" );
test_fail( +2 );

interface_ok( 'MyClassNotImplemented', 'MyRole' );


test_test "Test FAIL when 'interface_ok' - not ok";




done_testing;
