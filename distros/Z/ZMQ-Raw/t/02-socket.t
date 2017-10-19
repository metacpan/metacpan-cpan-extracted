#!perl

use Test::More;
use ZMQ::Raw;

ok (ZMQ::Raw::Socket->ZMQ_AFFINITY);
ok (ZMQ::Raw::Socket->ZMQ_IDENTITY);
ok (ZMQ::Raw::Socket->ZMQ_SUBSCRIBE);
ok (ZMQ::Raw::Socket->ZMQ_UNSUBSCRIBE);
ok (ZMQ::Raw::Socket->ZMQ_RATE);
ok (ZMQ::Raw::Socket->ZMQ_RECOVERY_IVL);
ok (ZMQ::Raw::Socket->ZMQ_SNDBUF);
ok (ZMQ::Raw::Socket->ZMQ_RCVBUF);
ok (ZMQ::Raw::Socket->ZMQ_RCVMORE);
ok (ZMQ::Raw::Socket->ZMQ_FD);
ok (ZMQ::Raw::Socket->ZMQ_EVENTS);
ok (ZMQ::Raw::Socket->ZMQ_TYPE);
ok (ZMQ::Raw::Socket->ZMQ_LINGER);
ok (ZMQ::Raw::Socket->ZMQ_RECONNECT_IVL);
ok (ZMQ::Raw::Socket->ZMQ_BACKLOG);
ok (ZMQ::Raw::Socket->ZMQ_RECONNECT_IVL_MAX);
ok (ZMQ::Raw::Socket->ZMQ_MAXMSGSIZE);
ok (ZMQ::Raw::Socket->ZMQ_SNDHWM);
ok (ZMQ::Raw::Socket->ZMQ_RCVHWM);
ok (ZMQ::Raw::Socket->ZMQ_MULTICAST_HOPS);
ok (ZMQ::Raw::Socket->ZMQ_RCVTIMEO);
ok (ZMQ::Raw::Socket->ZMQ_SNDTIMEO);
ok (ZMQ::Raw::Socket->ZMQ_LAST_ENDPOINT);
ok (ZMQ::Raw::Socket->ZMQ_ROUTER_MANDATORY);
ok (ZMQ::Raw::Socket->ZMQ_TCP_KEEPALIVE);
ok (ZMQ::Raw::Socket->ZMQ_TCP_KEEPALIVE_CNT);
ok (ZMQ::Raw::Socket->ZMQ_TCP_KEEPALIVE_IDLE);
ok (ZMQ::Raw::Socket->ZMQ_TCP_KEEPALIVE_INTVL);
ok (ZMQ::Raw::Socket->ZMQ_IMMEDIATE);
ok (ZMQ::Raw::Socket->ZMQ_XPUB_VERBOSE);
ok (ZMQ::Raw::Socket->ZMQ_ROUTER_RAW);
ok (ZMQ::Raw::Socket->ZMQ_IPV6);
ok (ZMQ::Raw::Socket->ZMQ_MECHANISM);
ok (ZMQ::Raw::Socket->ZMQ_PLAIN_SERVER);
ok (ZMQ::Raw::Socket->ZMQ_PLAIN_USERNAME);
ok (ZMQ::Raw::Socket->ZMQ_PLAIN_PASSWORD);
ok (ZMQ::Raw::Socket->ZMQ_CURVE_SERVER);
ok (ZMQ::Raw::Socket->ZMQ_CURVE_PUBLICKEY);
ok (ZMQ::Raw::Socket->ZMQ_CURVE_SECRETKEY);
ok (ZMQ::Raw::Socket->ZMQ_CURVE_SERVERKEY);
ok (ZMQ::Raw::Socket->ZMQ_PROBE_ROUTER);
ok (ZMQ::Raw::Socket->ZMQ_REQ_CORRELATE);
ok (ZMQ::Raw::Socket->ZMQ_REQ_RELAXED);
ok (ZMQ::Raw::Socket->ZMQ_CONFLATE);
ok (ZMQ::Raw::Socket->ZMQ_ZAP_DOMAIN);
ok (ZMQ::Raw::Socket->ZMQ_ROUTER_HANDOVER);
ok (ZMQ::Raw::Socket->ZMQ_TOS);
ok (ZMQ::Raw::Socket->ZMQ_CONNECT_RID);
ok (ZMQ::Raw::Socket->ZMQ_GSSAPI_SERVER);
ok (ZMQ::Raw::Socket->ZMQ_GSSAPI_PRINCIPAL);
ok (ZMQ::Raw::Socket->ZMQ_GSSAPI_SERVICE_PRINCIPAL);
ok (ZMQ::Raw::Socket->ZMQ_GSSAPI_PLAINTEXT);
ok (ZMQ::Raw::Socket->ZMQ_HANDSHAKE_IVL);
ok (ZMQ::Raw::Socket->ZMQ_SOCKS_PROXY);
ok (ZMQ::Raw::Socket->ZMQ_XPUB_NODROP);
ok (ZMQ::Raw::Socket->ZMQ_BLOCKY);
ok (ZMQ::Raw::Socket->ZMQ_XPUB_MANUAL);
ok (ZMQ::Raw::Socket->ZMQ_XPUB_WELCOME_MSG);
ok (ZMQ::Raw::Socket->ZMQ_STREAM_NOTIFY);
ok (ZMQ::Raw::Socket->ZMQ_INVERT_MATCHING);
ok (ZMQ::Raw::Socket->ZMQ_HEARTBEAT_IVL);
ok (ZMQ::Raw::Socket->ZMQ_HEARTBEAT_TTL);
ok (ZMQ::Raw::Socket->ZMQ_HEARTBEAT_TIMEOUT);
ok (ZMQ::Raw::Socket->ZMQ_XPUB_VERBOSER);
ok (ZMQ::Raw::Socket->ZMQ_CONNECT_TIMEOUT);
ok (ZMQ::Raw::Socket->ZMQ_TCP_MAXRT);
ok (ZMQ::Raw::Socket->ZMQ_THREAD_SAFE);
ok (ZMQ::Raw::Socket->ZMQ_MULTICAST_MAXTPDU);
ok (ZMQ::Raw::Socket->ZMQ_VMCI_BUFFER_SIZE);
ok (ZMQ::Raw::Socket->ZMQ_VMCI_BUFFER_MIN_SIZE);
ok (ZMQ::Raw::Socket->ZMQ_VMCI_BUFFER_MAX_SIZE);
ok (ZMQ::Raw::Socket->ZMQ_VMCI_CONNECT_TIMEOUT);
ok (ZMQ::Raw::Socket->ZMQ_USE_FD);

my $ctx = ZMQ::Raw::Context->new;
my $socket = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REQ);
isa_ok ($socket, "ZMQ::Raw::Socket");
$ctx->shutdown();

ok (!eval {$socket->send ('')});

my $error = $@;
isa_ok $error, 'ZMQ::Raw::Error';
like $error -> message, qr/Context was terminated/;
is $error -> file, 't/02-socket.t';
is $error -> line, 85;
is $error -> code, ZMQ::Raw::Error->ETERM;

$ctx = ZMQ::Raw::Context->new;
my $req = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REQ);
my $rep = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REP);
isa_ok ($req, "ZMQ::Raw::Socket");
isa_ok ($rep, "ZMQ::Raw::Socket");

ok (!eval {$rep->setsockopt (ZMQ::Raw::Socket->ZMQ_MAXMSGSIZE, "badtype")});
$error = $@;
isa_ok $error, 'ZMQ::Raw::Error';
like $error -> message, qr/Value is not an int/;
is $error -> code, -1;

ok (!eval {$rep->setsockopt (ZMQ::Raw::Socket->ZMQ_IPV6, "badtype")});

$rep->setsockopt (ZMQ::Raw::Socket->ZMQ_IPV6, 0);
$rep->setsockopt (ZMQ::Raw::Socket->ZMQ_MAXMSGSIZE, 100);
$rep->setsockopt (ZMQ::Raw::Socket->ZMQ_IDENTITY, "myid");

$rep->bind ('tcp://127.0.0.1:5555');
$req->connect ('tcp://localhost:5555');

# send/recv
$req->send ('hello');
ok (!defined ($req->recv (ZMQ::Raw->ZMQ_DONTWAIT)));

my $result = $rep->recv();
is $result, 'hello';


$rep->send ('world');
my $result2 = $req->recv();
is $result2, 'world';

# sendmsg/recvmsg (1 msg)
my $msg = ZMQ::Raw::Message->new;
$msg->data ('hello');

isnt $msg->size, 0;
$req->sendmsg ($msg);
isnt $msg->size, 0;

my $msg2 = $rep->recvmsg();
is $msg2->size, 5;
is $msg2->more, 0;

$rep->sendmsg ($msg2);

$msg = $req->recvmsg();
is $msg->size, 5;
is $msg->data(), 'hello';

# sendmsg/recvmsg (combin)
$msg = ZMQ::Raw::Message->new;
$msg->data ('hello');

my $monitor = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_PAIR);
$monitor->connect ('inproc://req.monitor');

$req->close;
$req->monitor ('inproc://req.monitor', ZMQ::Raw->ZMQ_EVENT_ALL);
$req->connect ('tcp://localhost:5555');

my $event = $monitor->recv();
ok (length ($event) > 0);

$req->sendmsg ($msg, ZMQ::Raw->ZMQ_SNDMORE);
$req->sendmsg ($msg, $msg, ZMQ::Raw->ZMQ_SNDMORE);
$req->sendmsg ('world');

my $data = $rep->recv();
is length ($data), 20;
is $data, 'hellohellohelloworld';

$rep->send ('done');
$req->recv();

$req->sendmsg ($msg, ZMQ::Raw->ZMQ_SNDMORE);
$req->sendmsg ($msg, $msg, ZMQ::Raw->ZMQ_SNDMORE);
$req->sendmsg ('world');

my @msgs;
@msgs = $rep->recv();
is scalar (@msgs), 4;
is $msgs[0], 'hello';
is $msgs[1], 'hello';
is $msgs[2], 'hello';
is $msgs[3], 'world';
@msgs = ();

$rep->send ('done');
$req->recv();

# sendmsg/recvmsg (multi msg)
$msg = ZMQ::Raw::Message->new;
$msg->data ('hello');
push @msgs, $msg;

$msg = ZMQ::Raw::Message->new;
$msg->data ('world');
push @msgs, $msg;

$req->sendmsg (@msgs, 'hello', 'world');

$msg2 = $rep->recvmsg();
is $msg2->more, 1;
is $msg2->data(), 'hello';

@msgs = $rep->recvmsg();
is scalar (@msgs), 3;

$msg2 = shift @msgs;
is $msg2->more, 1;
is $msg2->data(), 'world';

$msg2 = shift @msgs;
is $msg2->more, 1;
is $msg2->data(), 'hello';

$msg2 = shift @msgs;
is $msg2->more, 0;
is $msg2->data(), 'world';

$req->disconnect ('tcp://localhost:5555');
$rep->unbind ('tcp://127.0.0.1:5555');

done_testing;

