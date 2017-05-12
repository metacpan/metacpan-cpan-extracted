package Twiggy::Prefork::Metabolic::Server;
use strict;
use warnings;

use parent qw(Twiggy::Prefork::Server);

use constant DEBUG => $ENV{TWIGGY_DEBUG};

sub _accept_handler {
    my $self = shift;

    my $cb = $self->Twiggy::Server::_accept_handler( @_ );
    return $self->{max_reqs_per_child} == 0 ? $cb : sub {
        my ( $sock, $peer_host, $peer_port ) = @_;
        $self->{reqs_per_child}++;
        $cb->( $sock, $peer_host, $peer_port );

        if ( $self->{reqs_per_child} >= $self->{max_reqs_per_child} ) {
            DEBUG && warn sprintf "[%s] reach max reqs per child (%d/%d)\n",
                $$, $self->{reqs_per_child}, $self->{max_reqs_per_child};
            $self->{ready_to_exit}++ and return;
            $self->{exit_guard}->end;
        }
    };
}

1;
__END__
