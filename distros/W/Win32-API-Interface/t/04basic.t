use Test::More tests => 12;

use_ok('Win32::API::Interface');

package ITest;
use base qw/Win32::API::Interface/;

Test::More::ok( __PACKAGE__->generate( "kernel32", "GetCurrentProcessId", "", "I", 'GetCurrentProcessId' ) );
Test::More::ok( __PACKAGE__->generate( "kernel32", "GetCurrentProcessId", "", "I", 'get_pid' ) );
Test::More::ok( __PACKAGE__->generate(
    [ "kernel32", "GetCurrentProcess", "", "N" ],
    [ "kernel32", "GetCurrentProcess", "", "N", "get_process" ],
) );
Test::More::ok( __PACKAGE__->generate( {
    "kernel32" => [
        [ "GetCurrentThread", "", "N" ],
        [ "GetCurrentThread", "", "N", "get_thread" ],
    ]
} ) );

1;

Test::More::ok( my $obj = ITest->new, 'call "new"' );
Test::More::ok( $obj->GetCurrentProcessId, 'call "GetCurrentProcessId"' );
Test::More::ok( $obj->get_pid, 'call "get_pid"' );
Test::More::ok( $obj->GetCurrentProcess, 'call "GetCurrentProcess"' );
Test::More::ok( $obj->get_process, 'call "get_process"' );
Test::More::ok( $obj->GetCurrentThread, 'call "GetCurrentThread"' );
Test::More::ok( $obj->get_thread, 'call "get_thread"' );