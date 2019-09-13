package Mojo::Events::Dispatcher;
use Mojo::Base 'Mojo::EventEmitter';

use Mojo::Events::Listeners;
use Mojo::Server;

has app => sub { Mojo::Server->new->build_app('Mojo::HelloWorld') }, weak => 1;
has listeners => sub {
    my $self = shift;

    return Mojo::Events::Listeners->new(app => $self->app, namespaces => $self->namespaces);
};
has namespaces => sub { [] };

=head2 new

Initialize dispatcher and startup listeners

=cut

sub new {
    my $self = shift->SUPER::new(@_);

    for my $listener (@{ $self->listeners->registered }) {
        $self->on($listener->event => sub {
            my $self = shift;
            
            return $listener->handle(@_);
        });
    }

    return $self;
}

=head2 register

Proxy for listeners register

=cut

sub register {
    return shift->listeners->register(@_);
}

=head2 dispatch

Dispatch event

=cut

sub dispatch {
    return shift->emit(@_);
}

1;
