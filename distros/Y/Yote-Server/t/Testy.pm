package Testy;

use strict;
use warnings;

use Yote::Server;

use base 'Yote::Server::App';

sub _init {
    my $self = shift;
    $self->set_obj( $self->{STORE}->newobj );
}

sub test {
    my( $self, @args ) = @_;
    return ( "FOOBIE", "BLECH", @args );
}

sub tickle {
    my $self = shift;
    $self->get_obj->set_tickled( 1 );
}

1;
