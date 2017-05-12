package ZooKeeper::XUnit::Error;
use ZooKeeper;
use Test::LeakTrace;
use Test::Class::Moose;

sub test_exceptions {
    my ($self) = @_;

    throws_ok { ZooKeeper->new(hosts => "localhost:0") } "ZooKeeper::Error", "throw error when zookeeper cant connect";
}

sub test_leaks {
    my ($self) = @_;

    no_leaks_ok { eval {ZooKeeper->new(hosts => "localhost:0")} } "no leaks throwing exception from XS";
}

1;
