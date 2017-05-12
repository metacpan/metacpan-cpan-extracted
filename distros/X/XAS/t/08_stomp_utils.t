use strict;
use Test::More;
use Data::Hexdumper;
use Data::Dumper;
use lib '../lib';

BEGIN {

    unless ($ENV{RELEASE_TESTING}) {

        plan( skip_all => "Author tests not required for installation" );

    } else {

       plan(tests => 126);
       use_ok("XAS::Lib::Stomp::Utils");
       use_ok("XAS::Lib::Stomp::Parser");

    }

}

my $frame;
my $nframe;
my $buffer;
my $transaction = '1234';
my $stomp  = XAS::Lib::Stomp::Utils->new(-target => '1.2');
my $filter = XAS::Lib::Stomp::Parser->new(-target => '1.0');

# connect

$frame = $stomp->connect(
    -login    => 'test',
    -passcode => 'test'
);

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, 'CONNECT');
is($frame->header->login, 'test');
is($frame->header->passcode, 'test');
is($frame->body, '');

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "CONNECT");
is($nframe->header->login, "test");
is($nframe->header->passcode, 'test');
is($nframe->body, '');

# ack

$frame = $stomp->ack(
    -receipt      => 'testing',
    -subscription => $transaction,
    -message_id   => $transaction
);

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, 'ACK');
is($frame->header->receipt, 'testing');
is($frame->header->id, $transaction);
is($frame->header->subscription, $transaction);
is($frame->body, '');

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "ACK");
is($nframe->header->receipt, 'testing');
is($nframe->header->id, $transaction);
is($nframe->header->subscription, $transaction);
is($nframe->body, '');

# nack

$frame = $stomp->nack(
    -receipt      => 'testing',
    -subscription => $transaction,
    -message_id   => $transaction
);

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, 'NACK');
is($frame->header->receipt, 'testing');
is($frame->header->id, $transaction);
is($frame->header->subscription, $transaction);
is($frame->body, '');

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "NACK");
is($nframe->header->receipt, 'testing');
is($nframe->header->id, $transaction);
is($frame->header->subscription, $transaction);
is($nframe->body, '');

# begin

$frame = $stomp->begin(
    -receipt     => 'testing',
    -transaction => $transaction
);

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, 'BEGIN');
is($frame->header->receipt, 'testing');
is($frame->header->transaction, $transaction);
is($frame->body, '');

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "BEGIN");
is($nframe->header->receipt, 'testing');
is($nframe->header->transaction, $transaction);
is($nframe->body, '');

# commit

$frame = $stomp->commit(
    -receipt     => 'testing',
    -transaction => $transaction
);

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, 'COMMIT');
is($frame->header->receipt, 'testing');
is($frame->header->transaction, $transaction);
is($frame->body, '');

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "COMMIT");
is($nframe->header->receipt, 'testing');
is($nframe->header->transaction, $transaction);
is($nframe->body, '');

# abort

$frame = $stomp->abort(
    -receipt     => 'testing',
    -transaction => $transaction
);

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, 'ABORT');
is($frame->header->receipt, 'testing');
is($frame->header->transaction, $transaction);
is($frame->body, '');

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "ABORT");
is($nframe->header->receipt, 'testing');
is($nframe->header->transaction, $transaction);
is($nframe->body, '');

# subscribe

$frame = $stomp->subscribe(
    -destination  => '/queue/testing',
    -ack          => 'client',
    -id           => $transaction,
    -receipt      => 'testing',
);

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, 'SUBSCRIBE');
is($frame->header->receipt, 'testing');
is($frame->header->id, $transaction);
is($frame->header->ack, 'client');
is($frame->header->destination, '/queue/testing');
is($frame->body, '');

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "SUBSCRIBE");
is($nframe->header->receipt, 'testing');
is($nframe->header->id, $transaction);
is($nframe->header->ack, 'client');
is($nframe->header->destination, '/queue/testing');
is($nframe->body, '');

# unsubscribe

$frame = $stomp->unsubscribe(
    -destination  => '/queue/testing',
    -id           => $transaction,
    -receipt      => 'testing',
);

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, 'UNSUBSCRIBE');
is($frame->header->receipt, 'testing');
is($frame->header->id, $transaction);
is($frame->header->destination, '/queue/testing');
is($frame->body, '');

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "UNSUBSCRIBE");
is($nframe->header->receipt, 'testing');
is($nframe->header->id, $transaction);
is($nframe->header->destination, '/queue/testing');
is($nframe->body, '');

# send

my $message = "this is a test";
$frame = $stomp->send(
    -destination => '/queue/testing',
    -message     => $message,
    -transaction => $transaction,
    -receipt     => 'testing',
);

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, 'SEND');
is($frame->header->receipt, 'testing');
is($frame->header->transaction, $transaction);
is($frame->header->destination, '/queue/testing');
is($frame->body, $message);

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "SEND");
is($nframe->header->receipt, 'testing');
is($nframe->header->destination, '/queue/testing');
is($nframe->header->transaction, $transaction);
is($nframe->body, $message);

# disconnect

$frame = $stomp->disconnect(-receipt => 'testing');

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, 'DISCONNECT');
is($frame->header->receipt, 'testing');
is($frame->body, '');

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "DISCONNECT");
is($nframe->header->receipt, 'testing');
is($nframe->body, '');

# disconnect 2

$frame = $stomp->disconnect();

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, 'DISCONNECT');
is($frame->body, '');

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "DISCONNECT");
is($nframe->body, '');

# noop

$frame = $stomp->noop();

isa_ok($frame, "XAS::Lib::Stomp::Frame");
is($frame->command, "NOOP");
isa_ok($frame->header, 'XAS::Lib::Stomp::Frame::Headers');
is($frame->body, '');

$buffer = $frame->as_string;
$nframe = $filter->parse($buffer);

isa_ok($nframe, "XAS::Lib::Stomp::Frame");
is($nframe->command, "NOOP");
isa_ok($nframe->header, 'XAS::Lib::Stomp::Frame::Headers');
is($nframe->body, '');

