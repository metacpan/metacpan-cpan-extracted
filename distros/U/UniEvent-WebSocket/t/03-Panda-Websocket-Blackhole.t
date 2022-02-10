use 5.012;
use warnings;
use Test::More;
use UniEvent::WebSocket::Server;

my $loop = UniEvent::Loop->default_loop;
my $stoped = 0;

{
    my $client = new UniEvent::WebSocket::Client();
	
    $client->connect_callback(sub {
        $stoped = 1;
        $loop->stop();
    });
    
	$client->connect({
        uri => "ws://google.com:81",
    });
    $client->close(1000);
    
    $loop->run();
    ok($stoped, 'black hole aborted');
}

done_testing();
