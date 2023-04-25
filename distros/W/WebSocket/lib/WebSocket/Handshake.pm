##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Handshake.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/17
## Modified 2021/09/17
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Handshake;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( WebSocket );
    use vars qw( $VERSION );
    use Nice::Try;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{request}    = undef unless( defined( $self->{request} ) );
    $self->{response}   = undef unless( defined( $self->{response} ) );
    $self->{uri}        = undef unless( defined( $self->{uri} ) );
    $self->{version}    = '' unless( length( $self->{version} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub request { return( shift->_set_get_object( 'request', 'WebSocket::Request', @_ ) ); }

sub response { return( shift->_set_get_object( 'response', 'WebSocket::Response', @_ ) ); }

sub uri { return( shift->_set_get_uri( 'uri', @_ ) ); }

sub version { return( shift->_set_get_object_without_init( 'version', 'WebSocket::Version', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

WebSocket::Handshake - WebSocket Client & Server

=head1 SYNOPSIS

    use WebSocket::Handshake;
    my $this = WebSocket::Handshake->new || 
        die( WebSocket::Handshake->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

=head1 METHODS

=head2 request

Set or get a L<WebSocket::Request> object.

=head2 response

Set or get a L<WebSocket::Response> object.

=head2 uri

Set or get the request or response uri. When set, this returns a L<URI> object.

=head2 version

Set or get the L<WebSocket::Version> object representing the protocol version used.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<WebSocket::Handshake::Client>, L<WebSocket::Handshake::Server>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
