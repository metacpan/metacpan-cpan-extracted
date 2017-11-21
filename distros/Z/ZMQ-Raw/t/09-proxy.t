#!perl

use strict;
use warnings;
use Config;
use Test::More;
use ZMQ::Raw;

if (!$Config{useithreads})
{
	my $proxy = ZMQ::Raw::Proxy->new();
	isa_ok $proxy, 'ZMQ::Raw::Proxy';

	my $ctx = ZMQ::Raw::Context->new;
	my $frontend = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_ROUTER);
	$frontend->bind ('tcp://*:5557');

	my $backend = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_DEALER);
	$backend->bind ('tcp://*:5558');

	ok (!eval {$proxy->start ($frontend, $backend)});

	done_testing;
	exit;
}

require threads;
my $ctx = ZMQ::Raw::Context->new;

sub Proxy
{
	my $frontend = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_ROUTER);
	$frontend->bind ('tcp://*:5557');

	my $backend = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_DEALER);
	$backend->bind ('tcp://*:5558');

	my $proxy = ZMQ::Raw::Proxy->new();
	$proxy->start ($frontend, $backend);
}

my $proxy = threads->create ('Proxy');

my $req = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REQ);
$req->connect ('tcp://127.0.0.1:5557');

my $rep = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REP);
$rep->connect ('tcp://127.0.0.1:5558');

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

