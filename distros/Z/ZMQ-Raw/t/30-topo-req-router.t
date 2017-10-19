#!perl

use strict;
use warnings;
use Config;
use Test::More;
use ZMQ::Raw;

if (!$ENV{AUTHOR_TESTING})
{
	diag ("author testing, skipping");
	ok (1);
	done_testing;
	exit;
}

my $ctx = ZMQ::Raw::Context->new;

my $frontend = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_ROUTER);
$frontend->bind ('tcp://*:5600');

my $req = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REQ);
$req->connect ('tcp://localhost:5600');
$req->send ('hello');

my @msgs = $frontend->recvmsg();
is scalar (@msgs), 3;

isnt 0, $msgs[0]->size();
is 0, $msgs[1]->size();
isnt 0, $msgs[2]->size();

$frontend->sendmsg ($msgs[0], '', $msgs[2]);

my $out = $req->recv;
is $out, 'hello';

done_testing;

