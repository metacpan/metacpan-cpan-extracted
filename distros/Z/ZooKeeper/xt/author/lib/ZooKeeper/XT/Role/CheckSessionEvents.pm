package ZooKeeper::XT::Role::CheckSessionEvents;
use ZooKeeper;
use ZooKeeper::Constants;
use ZooKeeper::Test::Utils;
use Test::Class::Moose::Role;
use namespace::clean;

sub test_connection {
    my ($test) = @_;

    my $future = $test->new_future;
    my $zk = ZooKeeper->new(
        hosts      => test_hosts,
        dispatcher => $test->new_dispatcher,
        watcher    => sub { $future->done($_[0]) },
    );
    my $event = $future->get;

    is $event->{state}, ZOO_CONNECTED_STATE, 'got state for connection event';
    is $event->{type},  ZOO_SESSION_EVENT,   'got type for connection event';
}

1;
