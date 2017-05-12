use Test::More;
use strict;

use Voldemort::ProtoBuff::GetMessage;
use Voldemort::ProtoBuff::Connection;

BEGIN {
    eval("use Test::Pockito");
    plan skip_all => "Test::Pockito not installed" if $@;
}

my $pocket          = Test::Pockito->new("Mock");
my $connection_mock = $pocket->mock("Voldemort::ProtoBuff::Connection");

$pocket->when( $connection_mock->recv(4) )->then(0);
$pocket->{warn} = 1;

my $target = Voldemort::ProtoBuff::GetMessage->new;
my $result = $target->read($connection_mock);

ok( !defined $result, "Blank result, not deref an undefined result" );
done_testing();
