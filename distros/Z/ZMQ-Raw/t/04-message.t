#!perl

use Test::More;
use ZMQ::Raw;

is 1, ZMQ::Raw::Message->ZMQ_MORE;
is 3, ZMQ::Raw::Message->ZMQ_SHARED;

my $msg = ZMQ::Raw::Message->new;
isa_ok ($msg, "ZMQ::Raw::Message");

is $msg->more, 0;
is $msg->size, 0;
is $msg->data, undef;

ok ($msg->data ('hello'));
is $msg->size, 5;
my $result = $msg->data;
is $result, 'hello';

is $msg->get (ZMQ::Raw::Message->ZMQ_SHARED), 0;
is $msg->data ('world'), 'world';

my $clone = $msg->clone;
is 'world', $clone->data;

is $msg->routing_id(), undef;
is $msg->routing_id (123), 123;

done_testing;

