#!perl

use strict;
use warnings;
use Config;
use Test::More;
use ZMQ::Raw;

if (!$Config{useithreads})
{
	diag ("threads not available, skipping");
	ok (1);
	done_testing;
	exit;
}

require threads;
my $ctx = ZMQ::Raw::Context->new;

sub Proxy
{
	my $frontend = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_ROUTER);
	$frontend->bind ('tcp://*:5555');

	my $backend = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_DEALER);
	$backend->bind ('tcp://*:5556');

	my $proxy = ZMQ::Raw::Proxy->new();
	$proxy->start ($frontend, $backend);
}

my $proxy = threads->create ('Proxy');

my $req = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REQ);
$req->connect ('tcp://127.0.0.1:5555');

my $rep = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REP);
$rep->connect ('tcp://127.0.0.1:5556');

# send/recv
$req->send ('hello');
my $result = $rep->recv();
is $result, 'hello';

$rep->send ('world');
my $result2 = $req->recv();
is $result2, 'world';

$ctx->shutdown();
$proxy->join();

ok (1);
done_testing;

