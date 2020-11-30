use strict;
use warnings;
use lib 't/lib'; use MyTest;
use Net::SockAddr;

my $l = UE::Loop->default;

subtest 'bind' => sub {
    my $udp = new UniEvent::Udp;
    is($udp->type, UniEvent::Udp::TYPE, "new udp object type");

    $udp->bind_addr(SOCKADDR_LOOPBACK);
    my $sa = $udp->sockaddr;

    ok($sa->port, "Bound to port");
};

#subtest 'write burst' => sub {
#    my $srv = new UE::Udp;
#    $srv->bind_addr(SOCKADDR_LOOPBACK);
#    $srv->recv_start;
#    my $sa = $srv->sockaddr;
#    
#    my $cnt = 0;
#
#    $srv->receive_callback(sub {
#        my (undef, $str, $err) = @_;
#        is $str, "abcd";
#        $cnt++;
#    });
#
#    my $cli = new UE::Udp;
#    $cli->send("a", $sa);
#    $cli->send("b", $sa);
#    $cli->send("c", $sa);
#    $cli->send("d", $sa);
#    $cli->send_callback(sub {
#        $cnt++;
#    });
#
#    $l->run_once();
#    
#    is $cnt, 5;
#};

done_testing();
