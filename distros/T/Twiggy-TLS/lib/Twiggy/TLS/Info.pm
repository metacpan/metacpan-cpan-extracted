package Twiggy::TLS::Info;

use strict;
use warnings;

sub new {
    my ($class, $sock) = @_;

    bless {sock => $sock}, $class
}

sub client_certificate {
    my $self = shift;

    $self->{sock}->peer_certificate(@_);
}

sub cipher {
    my $self = shift;

    $self->{sock}->get_cipher;
}

1;
__END__

=head1 NAME

Twiggy::TLS::Info - TLS connection information

=head1 SYNOPSIS

In PSGI application:

    warn "Client's CommonName: " . $env->{"psgi.tls"}->client_certificate('cn');
    warn "Used cipher: " . $env->{"psgi.tls"}->cipher;

=head1 METHODS

=head2 client_certificate

Retrieve value from client certificate. If no field is given the internal
representation of certificate from Net::SSLeay is returned. The list of fields
can be found in L<IO::Socket::SSL> C<peer_certificate> method documentation.

=head2 cipher

Returns the string form of the cipher used for current connection.

=cut
