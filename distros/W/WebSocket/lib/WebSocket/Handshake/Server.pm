##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Handshake/Server.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/17
## Modified 2021/09/17
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Handshake::Server;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( WebSocket::Handshake );
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
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{request}  ||= WebSocket::Request->new( debug => $self->debug );
    $self->{response} ||= WebSocket::Response->new( debug => $self->debug );
    return( $self );
}

#sub as_string { return( shift->response->as_string ); }
sub as_string
{
    my $self = shift( @_ );
    my $data = $self->response->as_string( @_ ) || return( $self->pass_error( $self->response->error ) );
    return( $data );
}

sub is_done { return( shift->request->is_done ); }

sub make_frame
{
    my $self = shift( @_ );
    return( WebSocket::Frame->new( debug => $self->debug, version => $self->version, @_ ) );
}

sub parse
{
    my $self = shift( @_ );
    my $data = shift( @_ ) || return( $self->error( "No data to parse was provided." ) );
    my $req = $self->request;
    my $res = $self->response;
    return( $self ) if( $req->is_done );
    
    $req->debug( $self->debug );
    $req->parse( $data ) || return( $self->pass_error( $req->error ) );
    $res->version( $req->version );
    # $res->host( $req->host );

    $res->secure( $req->secure );
    $res->uri( $req->uri );
    $res->origin( $req->origin );

    # if( $req->version eq 'draft-ietf-hybi-00' )
    my $v = $req->version;
    if( ( $v->type eq 'hixie' && $v->revision == 76 ) ||
        ( $v->type eq 'hybi'  && $v->revision <= 3 ) )
    {
        $res->checksum( undef );
        $res->number1( $req->number1 );
        $res->number2( $req->number2 );
        $res->challenge( $req->challenge );
    }
#     elsif( $req->version eq 'draft-ietf-hybi-10' || 
#            $req->version eq 'draft-ietf-hybi-17' )
    elsif( $v->type eq 'hybi' && $v->revision >= 4 )
    {
        $res->key( $req->key );
    }
    return( $self );
}

1;

__END__

=encoding utf-8

=head1 NAME

WebSocket::Handshake::Server - WebSocket Server Handshake

=head1 SYNOPSIS

    use WebSocket::Handshake::Server;
    my $this = WebSocket::Handshake::Server->new || die( WebSocket::Handshake::Server->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

=head1 METHODS

=head2 as_string

Returns the server handshake as a string, meaning with its L<response header|WebSocket::Response> and possibly its body response to the client challenge if the protocole version used is an L<older version|WebSocket::Version>.

=head2 is_done

Set or get the boolean value of when the parsing of client request is done.

This method is actually a shortcut to L<WebSocket::Request/is_done>.

=head2 make_frame

Creates a new L<WebSocket::Frame> object passing it any argument provided. On top of those arguments provided, this method will also set the C<debug> and C<version> properties

=head2 parse

Initiate the parsing of the client request and setting some key information such as whether the connection is using ssl and is L<secure|WebSocket::Request/secure>, the L<uri|WebSocket::Request/uri>, the L<origin|WebSocket::Request>, the L<host|WebSocket::Request/host> among others. For more on information available, check L<WebSocket::Request>

If an error occurs, it returns C<undef> and sets an L<error|WebSocket::Exception> that can be retrieved with the L<error method|Module::Generic/error>

Returns the current object.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
