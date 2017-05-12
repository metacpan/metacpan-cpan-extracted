package ZooKeeper::XUnit::Role::CheckLeaks;
use Test::LeakTrace;
use ZooKeeper::Test::Utils qw(timeout);
use Test::Class::Moose::Role;
requires qw(new_dispatcher new_future);
use namespace::clean;

sub test_dispatcher_leaks {
    my ($self) = @_;
    no_leaks_ok { $self->new_dispatcher } 'no leaks constructing dispatcher';

    my $dispatcher = $self->new_dispatcher;
    no_leaks_ok {
        my $f = $self->new_future;
        $dispatcher->create_watcher("/" => sub{ $f->done }, type => "test");
        $dispatcher->trigger_event(path => "/", type => "test");
        timeout { $f->get };

        $f = $self->new_future;
        $dispatcher->create_watcher("/second" => sub{ $f->done }, type => "second-test");
        $dispatcher->trigger_event(path => "/second", type => "second-test");
        timeout { $f->get };
    } 'no leaks sending events through dispatcher';
}

sub test_watcher_constructor_leaks {
    my ($self) = @_;
    my $class  = ref($self->new_dispatcher);
    no_leaks_ok {
        my @watchers;
        my $dispatcher = $self->new_dispatcher;
        push @watchers, $dispatcher->create_watcher('/' => sub {}, type => 'watcher-test');
        push @watchers, $dispatcher->create_watcher('/second' => sub {}, type => 'second-watcher-test');
    } "no leaks creating $class watchers";
}

sub test_duplicate_watchers_leaks {
    my ($self) = @_;
    my $dispatcher = $self->new_dispatcher;

    no_leaks_ok {
        my $f1 = $self->new_future;
        $dispatcher->create_watcher("/" => sub{ $f1->done }, type => "test");

        my $f2 = $self->new_future;
        $dispatcher->create_watcher("/" => sub{ $f2->done }, type => "test");

        $dispatcher->trigger_event(path => "/", type => "test");
        timeout { $f1->get };
        timeout { $f2->get };
    } 'no leaks with duplicate watchers';
}

1;
