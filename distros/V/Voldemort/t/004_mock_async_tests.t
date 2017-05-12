use Test::More;

use strict;
use warnings;
use Carp;

BEGIN {
    eval("use Test::Pockito::Exported");
    eval("use Test::Pockito::DefaultMatcher 'is_defined'");
    plan skip_all => "Test::Pockito not installed" if $@;
}

use Test::Deep;

use Voldemort::Store;


my $mock_connection     = mock("Voldemort::ProtoBuff::Connection");
my $mock_put_handler    = mock("Voldemort::ProtoBuff::PutMessage");
my $mock_delete_handler = mock("Voldemort::ProtoBuff::DeleteMessage");
my $mock_get_handler    = mock("Voldemort::ProtoBuff::GetMessage");

my $store = Voldemort::Store->new( connection => $mock_connection, sync => 0 );
$store->default_store('test');

# setup some basic assumptions about certain calls
when( $mock_connection->flush )->default();
when( $mock_connection->is_connected )->default(1);
when( $mock_connection->can_write(is_defined) )->default(1);
when( $mock_connection->put_handler )->default($mock_put_handler);
when( $mock_connection->get_handler )->default($mock_get_handler);
when( $mock_connection->delete_handler )
  ->default($mock_delete_handler);

# test in order, put, get, delete
when(
    $mock_put_handler->write( $mock_connection, 'test', 'pizza', 'pepers', 3 ) )
  ->then(1);
when( $mock_get_handler->write( $mock_connection, 'test', 'pizza' ) )
  ->then(1);
when(
    $mock_delete_handler->write( $mock_connection, 'test', 'pizza' ) )->then(1);

$store->put( 'key' => 'pizza', 'value' => 'pepers', 'node' => 3 );
$store->get( 'key' => 'pizza' );
$store->delete( 'key' => 'pizza' );

ok( scalar keys %{ expected_calls() } == 0,
    "All calls executed as expected" );

when( $mock_put_handler->read($mock_connection) )->then(1);
when( $mock_get_handler->read($mock_connection) )
  ->then( 'cheese', [ 1, 2, 3 ] );
when( $mock_delete_handler->read($mock_connection) )->then(1);

my $put_success = $store->next_response;
my ( $value, $nodes ) = $store->next_response;
my $delete_success = $store->next_response;

ok( $value eq "cheese", "Get value succeeded" );
ok( eq_deeply( $nodes, [ 1, 2, 3 ] ), "Get node ids succeeds" );
ok( $put_success && $delete_success, "Write ops succeeded" );
ok( scalar keys %{ expected_calls() } == 0,
    "All calls executed as expected" );

done_testing;
