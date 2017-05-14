package ZeroMQ::Raw::Constants;
use strict;
use warnings;

my %CONSTANTS;

BEGIN {
    %CONSTANTS = (
        ZMQ_PAIR => 0,
        ZMQ_PUB => 1,
        ZMQ_SUB => 2,
        ZMQ_REQ => 3,
        ZMQ_REP => 4,
        ZMQ_XREQ => 5,
        ZMQ_XREP => 6,
        ZMQ_PULL => 7,
        ZMQ_PUSH => 8,
        ZMQ_UPSTREAM => 7,      # ZMQ_PULL,
        ZMQ_DOWNSTREAM => 8,    # ZMQ_PUSH,
        ZMQ_HWM => 1,
        ZMQ_SWAP => 3,
        ZMQ_AFFINITY => 4,
        ZMQ_IDENTITY => 5,
        ZMQ_SUBSCRIBE => 6,
        ZMQ_UNSUBSCRIBE => 7,
        ZMQ_RATE => 8,
        ZMQ_RECOVERY_IVL => 9,
        ZMQ_MCAST_LOOP => 10,
        ZMQ_SNDBUF => 11,
        ZMQ_RCVBUF => 12,
        ZMQ_RCVMORE => 13,
        ZMQ_FD => 14,
        ZMQ_EVENTS => 15,
        ZMQ_TYPE => 16,
        ZMQ_LINGER => 17,
        ZMQ_RECONNECT_IVL => 18,
        ZMQ_BACKLOG => 19,
        ZMQ_NOBLOCK => 1,
        ZMQ_SNDMORE => 2,
        ZMQ_POLLIN => 1,
        ZMQ_POLLOUT => 2,
        ZMQ_POLLERR => 4,
    );

    no strict 'refs';
    for my $k (keys %CONSTANTS){
        *{$k} = sub () { $CONSTANTS{$k} };
    }
};

use Sub::Exporter -setup => {
    exports => [ keys %CONSTANTS ],
};

1;
