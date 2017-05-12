package ZooKeeper::XUnit::Role::Dispatcher;
use Test::LeakTrace;
use ZooKeeper::Constants qw(ZOO_CHILD_EVENT ZOO_SESSION_EVENT);
use ZooKeeper::Test::Utils qw(timeout);
use Test::Class::Moose::Role;
requires qw(new_future new_dispatcher);

sub test_dispatcher {
    my ($self) = @_;

    my $dispatcher = $self->new_dispatcher;

    my $f = $self->new_future;
    $dispatcher->create_watcher('/' => sub{ $f->done(shift) }, type => "test");
    my $event = {type => 1, state => 2, path => 'test-path'};
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);

    my $rv; timeout { $rv = $f->get };
    is_deeply $rv, $event, "dispatcher called watcher with event";


    $f = $self->new_future;
    $dispatcher->create_watcher("/second" => sub{ $f->done(shift) }, type => "second-test");
    $event = {type => 2, state => 3, path => "second-test-path"};
    $dispatcher->trigger_event(
        path  => "/second",
        type  => "second-test",
        event => $event
    );

    timeout { $rv = $f->get };
    is_deeply $rv, $event, "dispatcher called second watcher with event";
}

sub test_session_events {
    my ($self) = @_;
    my $dispatcher = $self->new_dispatcher(ignore_session_events => 0);

    my $f = $self->new_future;
    $dispatcher->create_watcher("/" => sub{ $f->done(shift) }, type => "test");

    my $event = {type => ZOO_SESSION_EVENT, state => 2, path => "/"};
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);
    my $rv; timeout { $rv = $f->get };
    is_deeply $rv, $event, "dispatcher called watcher with session event";

    $f = $self->new_future;
    $event->{type} = ZOO_CHILD_EVENT;
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);
    timeout { $rv = $f->get };
    is_deeply $rv, $event, "dispatcher called watcher with additional watcher event";
}

sub test_ignore_session_events {
    my ($self) = @_;
    my $dispatcher = $self->new_dispatcher(ignore_session_events => 1);

    my $f = $self->new_future;
    $dispatcher->create_watcher("/" => sub{ $f->done(shift) }, type => "test");

    my $event = {type => ZOO_SESSION_EVENT, state => 2, path => "/"};
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);
    my $rv; timeout { $rv = $f->get };
    is_deeply $rv, undef, "dispatcher ignored session event";

    $f = $self->new_future;
    $event->{type} = ZOO_CHILD_EVENT;
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);
    timeout { $rv = $f->get };
    is_deeply $rv, $event, "dispatcher called watcher with watcher event";
}

sub test_duplicate_watchers {
    my ($self) = @_;
    my $dispatcher = $self->new_dispatcher;

    my $f1 = $self->new_future;
    $dispatcher->create_watcher('/' => sub{ $f1->done(shift) }, type => "test");
    my $f2 = $self->new_future;
    $dispatcher->create_watcher("/" => sub{ $f2->done(shift) }, type => "test");

    my $event = {type => 1, state => 2, path => 'test-path'};
    $dispatcher->trigger_event(path => "/", type => "test", event => $event);

    my $rv; timeout { $rv = $f1->get };
    is_deeply $rv, $event, "dispatcher called first watcher with event";

    $rv = undef; timeout { $rv = $f2->get };
    is_deeply $rv, $event, "dispatcher called duplicate watcher with event";
}

1;
