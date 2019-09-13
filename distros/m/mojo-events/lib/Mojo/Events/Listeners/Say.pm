package Mojo::Events::Listeners::Say;
use Mojo::Base 'Mojo::Events::Listener';

has event => 'say';

=head2 handler

Say $what

=cut

sub handler {
    my ($self, $what) = @_;

    say $what;
}

1;
