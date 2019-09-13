package Mojo::Events::Listener;
use Mojo::Base -base;

use Mojo::Server;

has app => sub { Mojo::Server->new->build_app('Mojo::HelloWorld') }, weak => 1;
has event => 'default';

=head2 handle

Handle event

=cut

sub handle {
    return shift->handler(@_);
}

=head2 handler

Define the handler

=cut

sub handler {
    warn "Implement in subclass."
}

1;
