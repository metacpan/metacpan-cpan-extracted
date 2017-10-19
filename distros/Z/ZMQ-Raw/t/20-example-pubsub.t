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

if (!$ENV{AUTHOR_TESTING})
{
	diag ("author testing, skipping");
	ok (1);
	done_testing;
	exit;
}

my $ctx = ZMQ::Raw::Context->new;

my $publisher = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_PUB);
$publisher->setsockopt (ZMQ::Raw::Socket->ZMQ_SNDHWM, 1100000);
$publisher->bind ('tcp://*:5561');

my $syncservice = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REP);
$syncservice->bind ('tcp://*:5562');

sub SynchronisedSubscriber
{
	my ($id) = @_;

	print STDERR "Started subscriber ($id)\n";

	my $subscriber = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_SUB);
	$subscriber->connect ('tcp://localhost:5561');
	$subscriber->setsockopt (ZMQ::Raw::Socket->ZMQ_SUBSCRIBE, "");

	sleep 2;

	my $syncservice = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REQ);
	$syncservice->connect ('tcp://localhost:5562');
	$syncservice->send ('');
	$syncservice->recv();

	my $count = 0;
	while (1)
	{
		my $request = $subscriber->recv();
		last if ($request eq 'END');

		++$count;
	}

	print STDERR "Received $count updates ($id)\n";
}

# Start subscriber threads...
require threads;
my @threads;
for (my $i = 0; $i < 2; ++$i)
{
	my $thr = threads->create ('SynchronisedSubscriber', $i);
	push @threads, $thr;
}

foreach (@threads)
{
	# Synchronise subscribers
	$syncservice->recv();
	$syncservice->send ('');
}

print STDERR "Broadcasting messages...\n";
for (my $i = 0; $i < 1000; ++$i)
{
	$publisher->send ('hello');
}

$publisher->send ('END');

foreach my $thr (@threads)
{
	$thr->join();
}

ok (1);
done_testing;

