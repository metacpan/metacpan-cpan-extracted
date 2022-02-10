use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

my $loop = UniEvent::Loop->default_loop;
my $state = 0;
my ($server, $port) = MyTest::make_server();

my $cl1 = new UniEvent::Tcp();
$cl1->connect('127.0.0.1', $port);
$cl1->shutdown(sub {
	$state++;
	my $cl2 = new UniEvent::Tcp();
	$cl2->connect('127.0.0.1', $port, 1, sub {
		$state++;
		$loop->stop();
	});
});

$server->run();
$loop->run();

ok($state == 2);
done_testing();
