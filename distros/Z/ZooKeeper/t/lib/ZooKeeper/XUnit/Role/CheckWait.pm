package ZooKeeper::XUnit::Role::CheckWait;
use ZooKeeper::Test::Utils qw(timeout);
use Test::Class::Moose::Role;
requires qw(new_delay new_dispatcher);
use namespace::clean;

sub test_wait {
    my ($self) = @_;
    my $dispatcher = $self->new_dispatcher;

    $dispatcher->create_watcher('/' => sub { }, type => 'test');

    my $timedout = timeout { $dispatcher->wait } 0.1;
    ok $timedout, 'timed out waiting before event trigger';

    $timedout = timeout { $dispatcher->wait(1) } 0.1;
    ok $timedout, 'timed out when passed long wait';

    $timedout = timeout { $dispatcher->wait(0.1) } 1;
    ok !$timedout, 'returned when passed short wait';

    my $rv; timeout { $rv = $dispatcher->wait(0.1) };
    is $rv, undef, 'returned undef when no events';

    my $event = {type => 1, state => 2, path => 'test-path'};
    my $delay = $self->new_delay(0.1, sub {
        $dispatcher->trigger_event(
            path  => '/',
            type  => 'test',
            event => $event,
        )
    });
    timeout { $rv = $dispatcher->wait };
    is_deeply $rv, $event, 'wait returned triggered event';
}

1;
