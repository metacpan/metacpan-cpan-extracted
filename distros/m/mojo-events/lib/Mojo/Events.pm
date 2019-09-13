package Mojo::Events;
use Mojo::Base -base;

use Mojo::Events::Dispatcher;
use Mojo::Events::Listeners;

use Mojo::Server;

our $VERSION = '0.0.2';

has app => sub { Mojo::Server->new->build_app('Mojo::HelloWorld') }, weak => 1;
has namespaces => sub { [] };

has dispatcher => sub {
    my $self = shift;

    return Mojo::Events::Dispatcher->new(app => $self->app, namespaces => $self->namespaces);
};

1;

=encoding utf8

=head1 NAME

Mojo::Events - Dispatch and handle sync/async events in Mojolicious

=head1 SYNOPSIS

    use Mojo::Events;

    my $events = Mojo::Events->new(app => $app, namespaces => ['Listeners::Namespace']);

    $events->dispatcher->dispatch(say => 'Hello!');

=head1 DESCRIPTION

L<Mojo::Events> is a very basic implementation for events/listeners

=head1 ATTRIBUTES

L<Mojo::Events> inherits all attributes from L<Mojo::Base>.

=head1 METHODS

L<Mojo::Events> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 new

    my $events = Mojo::Events->new(app => $app, namespaces => ['Listeners::Namespace']);

Events manipulator object.

=head2 dispatcher

    my $dispatcher = $events->dispatcher;

    # dispatch an event
    $dispatcher->dispatch(event_name => (<event args>));

    # register a new listener
    $dispatcher->register(My::Custom::Listener->new(app => $mojolicious));

Events dispatcher.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
