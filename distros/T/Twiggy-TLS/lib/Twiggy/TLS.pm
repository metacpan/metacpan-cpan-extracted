package Twiggy::TLS;

use strict;
use warnings;

use 5.008_001;
our $VERSION = '0.0019';

1;
__END__

=head1 NAME

Twiggy::TLS - Twiggy server with TLS support.

=head1 SYNOPSIS

    twiggy --server Twiggy::TLS --tls-key key.pem --tls-cert cert.pem

See L</ATTRIBUTES> for more details.

    use Twiggy::Server::TLS;

    my $server = Twiggy::Server::TLS->new(
        host     => $host,
        port     => $port,
        tls_key  => $key_filename,
        tls_cert => $cert_filename
    );
    $server->register_service($app);

    AE::cv->recv;

=head1 DESCRIPTION

Twiggy::TLS extends Twiggy with a TLS support.

=head1 ATTRIBUTES

All files must be in PEM format. You can merge multiply entities in a one file
(like server key and certificate).

=head2 tls_version

Sets the version of the SSL protocol used to transmit data. The default is
C<SSLv23:!SSLv2>. See C<SSL_version> of L<IO::Socket::SSL> for other values.

=head2 tls_ciphers

This directive describes the list of cipher suites the server supports for
establishing a secure connection. Cipher suites are specified in the OpenSSL
cipherlist format
L<http://www.openssl.org/docs/apps/ciphers.html#CIPHER_STRINGS>.

The default is C<HIGH:!aNULL:!MD5>.

=head2 tls_key

Path to the server private key file.

=head2 tls_cert

Path to the server certificate file.

=head2 tls_verify

Controls the verification of the peer identity. Possible values are:

=over 4

=item C<off>

Default. Disable peer verification.

=item C<on>

Request peer certificate and verify it against CA. You can specify CA
certificate with C<tls_ca> option.

=item C<optional>

Same as C<on>, but allows users that has not passed verification.

=back

=head2 tls_ca

Path to file that contains CA certificate. Used for peer verification.

=head1 TLS INFORMATION

TLS connection information stored in the environment key C<psgi.tls>, see
L<Twiggy::TLS::Info>.

=head1 DEBUGGING

You can set the C<TWIGGY_DEBUG> environment variable to get diagnostic
information.

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 AUTHOR

Sergey Zasenko

=head1 SEE ALSO

L<Twiggy>

=cut
