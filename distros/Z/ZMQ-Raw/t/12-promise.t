#!perl

use Test::More;
use ZMQ::Raw;

my $ctx = ZMQ::Raw::Context->new;
my $loop = ZMQ::Raw::Loop->new ($ctx);

my $then = 0;
my $promise = ZMQ::Raw::Loop::Promise->new ($loop);
isa_ok $promise, 'ZMQ::Raw::Loop::Promise';
is $promise->status, ZMQ::Raw::Loop::Promise->PLANNED;

my $chained1 = $promise->then (sub
	{
		++$then;
		return { id => 'chained1' };
	}
);

isa_ok $chained1, 'ZMQ::Raw::Loop::Promise';
is $chained1->status, ZMQ::Raw::Loop::Promise->PLANNED;

my $chained2 = $chained1->then (sub
	{
		++$then;
		return { id => 'chained2' };
	}
);

isa_ok $chained2, 'ZMQ::Raw::Loop::Promise';
is $chained2->status, ZMQ::Raw::Loop::Promise->PLANNED;

$chained2
->then (sub { ++$then })
->then (sub { ++$then })
->then (sub { ++$then });

my $failed1 = ZMQ::Raw::Loop::Promise->new ($loop);
my $failed2 = $failed1->then (sub
	{
		die "me too\n";
	}
);


my $timer1 = ZMQ::Raw::Loop::Timer->new (
	timer => ZMQ::Raw::Timer->new ($ctx, after => 1000),
	on_timeout => sub
	{
		$promise->keep ({code => 0});
		$failed1->break ('boom');
	}
);

my $count = 0;
my $timer2 = ZMQ::Raw::Loop::Timer->new (
	timer => ZMQ::Raw::Timer->new ($ctx, after => 100, interval => 100),
	on_timeout => sub
	{
		++$count;
	}
);

my $fallback = 0;
my $timer3 = ZMQ::Raw::Loop::Timer->new (
	timer => ZMQ::Raw::Timer->new ($ctx, after => 10000),
	on_timeout => sub
	{
		++$fallback;
		$loop->terminate();
	}
);

my $event = ZMQ::Raw::Loop::Event->new ($ctx,
	on_set => sub
	{
		$promise->await();
		is $promise->status, ZMQ::Raw::Loop::Promise->KEPT;
		is $chained1->status, ZMQ::Raw::Loop::Promise->KEPT;
		is $chained2->status, ZMQ::Raw::Loop::Promise->KEPT;

		my $result = $promise->result;
		isa_ok $result, 'HASH';
		ok (exists ($result->{code}));

		$result = $chained1->result;
		isa_ok $result, 'HASH';
		ok (exists ($result->{id}));

		$result = $chained2->result;
		isa_ok $result, 'HASH';
		ok (exists ($result->{id}));

		$loop->terminate();
	}
);

$event->set;

is $then, 0;
$loop->run();
$loop->add ($timer1);
$loop->add ($timer2);
$loop->add ($timer3);
$loop->add ($event);
$loop->run();
is $fallback, 0;

ok ($count >= 5);
is $loop->poller->size, 0;
is $then, 5;

is $failed1->status, ZMQ::Raw::Loop::Promise->BROKEN;
is $failed1->cause, 'boom';
is $failed2->status, ZMQ::Raw::Loop::Promise->BROKEN;
like $failed2->cause, qr#me too#;


# add promise to loop
my $timer4_count = 0;
my $lpromise = ZMQ::Raw::Loop::Promise->new ($loop);
my $timer4 = ZMQ::Raw::Loop::Timer->new (
	timer => ZMQ::Raw::Timer->new ($ctx, after => 100, interval => 100),
	on_timeout => sub
	{
		my $timer = shift;
		if (++$timer4_count >= 5)
		{
			$timer->cancel();
			$loop->terminate();
			$lpromise->keep ('cool');
		}
	}
);

$loop->add ($lpromise);
$loop->add ($timer4);
$loop->run;

is $lpromise->status, ZMQ::Raw::Loop::Promise->KEPT;
ok (!eval {$$lpromise->cause});
is $timer4_count, 5;

done_testing;

