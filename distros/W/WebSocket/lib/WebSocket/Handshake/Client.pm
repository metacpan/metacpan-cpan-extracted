##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Handshake/Client.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/17
## Modified 2021/09/17
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Handshake::Client;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( WebSocket::Handshake );
    use vars qw( $VERSION );
    use Nice::Try;
    use WebSocket::Frame;
    use WebSocket::Request;
    use WebSocket::Response;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->{_init_params_order}   = [qw( request response )];
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{request}  ||= WebSocket::Request->new;
    $self->{response} ||= WebSocket::Response->new;
    if( my $version = $self->version )
    {
        $self->request->version( $version );
        $self->response->version( $version );
    }
    $self->{request}->debug( $self->debug );
    $self->{response}->debug( $self->debug );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $data = $self->request->as_string( @_ ) || return( $self->pass_error( $self->request->error ) );
    return( $data );
}

sub is_done { return( shift->response->is_done ); }

sub make_frame
{
    my $self = shift( @_ );
    return( WebSocket::Frame->new( debug => $self->debug, masked => 1, version => $self->version, @_ ) );
}

sub parse
{
    my $self = shift( @_ );
    my $data = shift( @_ ) || return( $self->error( "No data provided to parse" ) );
    my $req  = $self->request;
    my $res  = $self->response;
    unless( $res->is_done )
    {
        $res->debug( $self->debug );
        $res->parse( $data ) || return( $self->pass_error( $res->error ) );
        if( $res->is_done )
        {
            my $v = $req->version;
            # Checksums are used in draft hixie revision 76 and drafts hybi up until and including revision 3
            if( ( ( $v->type eq 'hixie' && $v->revision == 76 ) ||
                  ( $v->type eq 'hybi'  && $v->revision <= 3 )
                ) &&  
                $req->checksum ne $res->checksum )
            {
                return( $self->error( "Checksum is wrong." ) );
            }
        }
    }
    return( $self );
}

sub uri
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $uri = $self->_set_get_uri( 'uri', @_ ) || return( $self->pass_error );
        $self->request->debug( $self->debug );
        my $req = $self->request;
        $self->request->secure(1) if( $uri->scheme eq 'wss' );
        my $host = $uri->host;
        if( $uri->port && 
            ( $uri->scheme eq 'wss' ? $uri->port ne 443 : $uri->port ne 80 ) )
        {
            $host .= ':' . $uri->port;
        }
        $req->host( $host );
        $req->uri( $uri );
    }
    return( $self->_set_get_uri( 'uri' ) );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

WebSocket::Handshake::Client - WebSocket Client Handshake

=head1 SYNOPSIS

    use WebSocket::Handshake::Client;
    my $this = WebSocket::Handshake::Client->new( uri => "ws://localhost:8181/some/where" ) || 
        die( WebSocket::Handshake::Client->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

=head1 METHODS

=head2 as_string

Returns the client handshake as a string, meaning with its L<request header|WebSocket::Request> and possibly its body request to the server containing the challenge if the protocole version used is an L<older version|WebSocket::Version>.

=head2 is_done

Set or get the boolean value of when the parsing of server response is done.

This method is actually a shortcut to L<WebSocket::Response/is_done>.

=head2 make_frame

Creates a new L<WebSocket::Frame> object passing it any argument provided. On top of those arguments provided, this method will also set the C<debug> and C<version> properties

=head2 parse

Initiate the parsing of the L<server response|WebSocket::Response>.

If an error occurs, it returns C<undef> and sets an L<error|WebSocket::Exception> that can be retrieved with the L<error method|Module::Generic/error>

Returns the current object.

=head2 uri

Set or get the uri for the remote server connection. This returns a L<URI::wss> object.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<WebSocket::Client>, L<WebSocket::Handshake>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
