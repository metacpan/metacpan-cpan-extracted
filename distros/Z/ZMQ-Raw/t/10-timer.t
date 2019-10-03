#!perl

use Test::More;
use ZMQ::Raw;

my $ctx = ZMQ::Raw::Context->new;
my $poller = ZMQ::Raw::Poller->new;

# oneshot
my $timer1 = ZMQ::Raw::Timer->new ($ctx,
	after => 200
);
isa_ok ($timer1, "ZMQ::Raw::Timer");

is $timer1->id, 1;

my $s1 = $timer1->socket;
isa_ok ($s1, "ZMQ::Raw::Socket");

$poller->add ($s1, ZMQ::Raw->ZMQ_POLLIN);

is 0, $poller->wait (100);
is 1, $poller->wait (500);

my $events = $poller->events ($s1);
ok ($events & ZMQ::Raw->ZMQ_POLLIN);
$s1->recv;

is 0, $poller->wait (100);
$events = $poller->events ($s1);
ok (!($events & ZMQ::Raw->ZMQ_POLLIN));

# interval
my $timer2 = ZMQ::Raw::Timer->new ($ctx,
	after => 20,
	interval => 50
);

my $s2 = $timer2->socket;
ok (!eval {$s2->close});

$poller->add ($s2, ZMQ::Raw->ZMQ_POLLIN);

is 1, $poller->wait (200);
$s2->recv;
is 0, $poller->wait (0);
is 1, $poller->wait (200);
$s2->recv;
is 0, $poller->wait (0);

$poller->remove ($s1);
$poller->remove ($s2);
is $poller->size, 0;

my $timer3 = ZMQ::Raw::Timer->new ($ctx,
	after => 500
);

my $s3 = $timer3->socket;
$poller->add ($s3, ZMQ::Raw->ZMQ_POLLIN);
is $poller->size, 1;

is 0, $poller->wait (100);
$timer3->reset;
is 0, $poller->wait (100);
$timer3->reset;
is 0, $poller->wait (100);
$timer3->reset;
is 0, $poller->wait (100);
$timer3->reset;
is $poller->wait (1000), 1;

$poller->remove ($s3);
is $poller->size, 0;

my $timer4 = ZMQ::Raw::Timer->new ($ctx,
	after => 500
);

my $s4 = $timer4->socket;
$poller->add ($s4, ZMQ::Raw->ZMQ_POLLIN);
is $poller->size, 1;

is 0, $poller->wait (100);
$timer4->cancel;
is 0, $poller->wait (200);

$poller->remove ($s4);

my $timer4 = ZMQ::Raw::Timer->new ($ctx,
	after => 200,
	interval => 200,
);

is 200, $timer4->interval();
is 300, $timer4->interval (300);

done_testing;

