#!perl

use Test::More;
use ZMQ::Raw;

ZMQ::Raw::Curve->keypair();
my ($private, $public) = ZMQ::Raw::Curve->keypair();

ok ($public ne $private);
is length ($public), 40;
is length ($private), 40;

ok (!eval {ZMQ::Raw::Curve->public ("badlength")});
is $public, ZMQ::Raw::Curve->public ($private);

$private = ZMQ::Raw::Curve->keypair();
is length ($private), 40;

my ($s_private, $s_public) = ZMQ::Raw::Curve->keypair();
my ($c_private, $c_public) = ZMQ::Raw::Curve->keypair();

my $ctx = ZMQ::Raw::Context->new;
my $req = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REQ);
$req->setsockopt (ZMQ::Raw::Socket->ZMQ_CURVE_SECRETKEY, $c_private);
$req->setsockopt (ZMQ::Raw::Socket->ZMQ_CURVE_PUBLICKEY, $c_public);
$req->setsockopt (ZMQ::Raw::Socket->ZMQ_CURVE_SERVERKEY, $s_public);
$req->connect ('tcp://127.0.0.1:5555');

my $rep = ZMQ::Raw::Socket->new ($ctx, ZMQ::Raw->ZMQ_REP);
$rep->setsockopt (ZMQ::Raw::Socket->ZMQ_CURVE_SECRETKEY, $s_private);
$rep->setsockopt (ZMQ::Raw::Socket->ZMQ_CURVE_SERVER, 1);
$rep->bind ('tcp://*:5555');

# send/recv
$req->send ('hello');
my $result = $rep->recv();
is $result, 'hello';

$rep->send ('world');
my $result2 = $req->recv();
is $result2, 'world';

done_testing;

