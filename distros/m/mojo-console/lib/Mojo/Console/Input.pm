package Mojo::Console::Input;
use Mojo::Base -base;

sub ask {
    my $self = shift;

    my $answer = <STDIN>;
    chomp $answer;

    return $answer;
}

1;

=encoding utf8

=head1 NAME

Mojo::Console::Input - read things from STDIN

=head1 METHODS

L<Mojo::Console::Input> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 ask

    my $answer = $self->ask;

=cut
