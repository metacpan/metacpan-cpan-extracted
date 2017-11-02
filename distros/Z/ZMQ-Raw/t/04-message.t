#!perl

use Test::More;
use ZMQ::Raw;

is 1, ZMQ::Raw::Message->ZMQ_MORE;
is 3, ZMQ::Raw::Message->ZMQ_SHARED;

is "Routing-Id", ZMQ::Raw::Message->ZMQ_MSG_PROPERTY_ROUTING_ID;
is "Socket-Type", ZMQ::Raw::Message->ZMQ_MSG_PROPERTY_SOCKET_TYPE;
is "User-Id", ZMQ::Raw::Message->ZMQ_MSG_PROPERTY_USER_ID;
is "Peer-Address", ZMQ::Raw::Message->ZMQ_MSG_PROPERTY_PEER_ADDRESS;

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

is $msg->group(), '';
is $msg->group ("test"), "test";

done_testing;

