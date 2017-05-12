# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl UDT-Simple.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use strict;
use warnings;
use Socket;
use Test::More tests => 3;
use threads;
use Data::Dumper;
BEGIN { use_ok('UDT::Simple') };
my $message = 'hello world';
my ($server) = threads->create(sub {
    my $u = UDT::Simple->new(AF_INET,SOCK_DGRAM);
    $u->udt_sndbuf(3001);
    $u->udt_rcvbuf(3001);
    $u->udp_sndbuf(3001);
    $u->udp_rcvbuf(3001);
    $u->bind("127.0.0.1","12344");
    $u->listen(4);
    my $x = $u->accept();
    my $r = $x->recv(length($message));
    $x->close();
    $u->close();
    return $r;
});
my $u = UDT::Simple->new(AF_INET,SOCK_DGRAM);
$u->udt_sndbuf(3000);
$u->udt_rcvbuf(3000);
$u->udp_sndbuf(3000);
$u->udp_rcvbuf(3000);

$u->connect("127.0.0.1","12344");
is length($message),$u->send($message), "send length does not match message len";
$u->close();
my $r = $server->join();
is $r,$message, "received message does not match";
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

