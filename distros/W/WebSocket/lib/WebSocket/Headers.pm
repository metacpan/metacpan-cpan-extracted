##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Headers.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/20
## Modified 2021/09/20
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Headers;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTTP::Headers Module::Generic );
    use Nice::Try;
    use Want;
    our $VERSION = 'v0.1.0';
};

sub exists
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    return(0) if( !defined( $name ) || !length( $name ) );
    return( CORE::exists( $self->{ $name } ) );
}

sub header
{
    my $self = shift( @_ );
    my @args = @_;
    # $self->message( 3, "Arguments received are: ", sub{ $self->dump( \@args ) });
    # Set mode
    if( scalar( @args ) > 1 )
    {
        for( my $i = 0; $i < scalar( @args ); $i += 2 )
        {
#             if( $args[$i] eq 'debug' )
#             {
#                 my $trace = $self->_get_stack_trace;
#                 print( STDERR ref( $self ), "::header: called with 'debug' header -> $trace\n" );
#             }
            my $v = $args[$i + 1];
            if( $self->_is_array( $v ) && $self->_is_object( $v ) )
            {
                $args[$i + 1] = [@$v];
            }
            elsif( overload::Overloaded( $v ) && overload::Method( $v, '""' ) )
            {
                $args[$i + 1] = "$v";
            }
        }
    }
    
    try
    {
        # $self->message( 3, "Calling HTTP::Headers->header with args ", sub{ $self->dump( \@args ) });
        my @rv = $self->SUPER::header( @args );
        # $self->message( 3, "\@rv contains: ", sub{ $self->dump( \@rv ) }, " for initial arguments: ", sub{ $self->dump( \@args )});
        # Convert
        for( my $i = 0; $i < scalar( @rv ); $i++ )
        {
            if( !ref( $rv[$i] ) )
            {
                $rv[$i] = $self->new_scalar( $rv[$i] );
            }
            elsif( ref( $rv[$i] ) eq 'ARRAY' )
            {
                $rv[$i] = $self->new_array( $rv[$i] );
            }
        }
        if( !scalar( @rv ) )
        {
            # $self->message( 3, "HTTP::Headers->header returned empty/null" );
            @rv = ( $self->new_scalar( undef ) );
        }
        # $self->message( 3, "Returning -> ", sub{ $self->dump( \@rv ) });
        return( @rv ) if( wantarray() );
        return( $rv[0] ) if( @rv <= 1 );
        return( join( ", ", @rv ) );
    }
    catch( $e )
    {
        return( $self->error( "Error ", ( scalar( @args ) > 1 ? 'setting' : 'getting' ), " header value(s): $e" ) );
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

WebSocket::Headers - WebSocket Headers Class

=head1 SYNOPSIS

    use WebSocket::Headers;
    my $h = WebSocket::Headers->new || die( WebSocket::Headers->error, "\n" );
    $h->header('Content-Type' => 'text/plain');  # set
    $ct = $h->header('Content-Type');            # get

And now also:

    my $conn = $h->header( 'connection' )->split( qr/\s*,\s*/ ) if( $h->header( 'connection' )->length > 7 );
    die( "Connection header has no \"Upgrade\" value." ) ) unless( $conn->grep(sub{ lc( $_ ) eq 'upgrade' })->length );

    die( "Bad value\n" ) if( $h->header( 'upgrade' )->lc ne 'websocket' );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This package inherits all its methods from L<HTTP::Headers> and provides convenient chaining on the value returned from L<header|HTTP::Headers/header>. For convenience those relevant methods are also documented here.

Any header value returned by L<HTTP::Headers/header> that is an array will be returned as an L<Module::Generic::Array> object and regular string will be returned as L<Module::Generic::Scalar> object.

=head1 METHODS

=head2 as_string

Takes an optional C<$eol> parameter to be used as end of line.

Return the header fields as a formatted MIME header. Since it internally uses the L</scan> method to build the string, the result will use case as suggested by HTTP spec, and it will follow recommended "Good Practice" of ordering the header fields. Long header values are not folded.

The optional C<$eol> parameter specifies the line ending sequence to use. The default is "\n". Embedded "\n" characters in header field values will be substituted with this line ending sequence.

=head2 authorization

A user agent that wishes to authenticate itself with a server or a proxy, may do so by including these headers.

=head2 authorization_basic

This method is used to get or set an authorization header that use the "Basic Authentication Scheme".  In array context it will return two values; the user name and the password. In scalar context it will return I<"uname:password"> as a single string value.

When used to set the header value, it expects two arguments. I<E.g.>:

    $h->authorization_basic( $uname, $password );

The method will croak if the $uname contains a colon ':'.

=head2 clear

This will remove all header fields.

=head2 content_length

A decimal number indicating the size in bytes of the message content.

=head2 exists

Returns true if the provided header exists, false otherwise. The value can be provided in a case insensitive manner and the dash (C<->) can be provided as underscore (C<_>)

=head2 flatten

Returns the list of pairs of keys and values.

=head2 header

Set or get the WebSocket header.

In set mode, if an L<array object|Module::Generic::Array>, it will convert it into a regular array and if a L<scalar object|Module::Generic::Scalar> is provided, it will be converted into its actual underlying value.

You can set multiple headers in one call.

    $header->header( Origin => 'https://example.org:8080' );
    $header->header( 'Sec-WebSocket-Protocol' => 'chat,com.example.v2', 'Sec-WebSocket-Version' => 13 );
    my $accept = $header->header( 'Sec-WebSocket-Accept' );

In get mode, it does the reverse operation, i.e. transform an array into an array object and a string into an scalar object.

It returns a list in list context, or a comma separated values in scalar context.

=head2 header_field_names

Returns the list of distinct names for the fields present in the header. The field names have case as suggested by HTTP spec, and the names are returned in the recommended "Good Practice" order.

In scalar context return the number of distinct field names.

=head2 proxy_authenticate

This header must be included in a C<407 Proxy Authentication Required> response.

=head2 proxy_authorization

A user agent that wishes to authenticate itself with a server or a proxy, may do so by including these headers.

=head2 proxy_authorization_basic

Same as authorization_basic() but will set the C<Proxy-Authorization> header instead.

=head2 push_header

Add a new field value for the specified header field. Previous values for the same field are retained.

As for the C</header> method, the field name (C<$field>) is not case sensitive and '_' can be used as a replacement for '-'.

The C<$value> argument may be a scalar or a reference to a list of scalars.

    $header->push_header( 'Sec-WebSocket-Protocol' => 'chat' );
    $header->push_header( 'Sec-WebSocket-Protocol' => [qw( com.example.chat.v2 com.example.chat.v1 )] );

=head2 remove_header

This function removes the header fields with the specified names.

The header field names (C<$field>) are not case sensitive and '_' can be used as a replacement for '-'.

The return value is the values of the fields removed. In scalar context the number of fields removed is returned.

Note that if you pass in multiple field names then it is generally not possible to tell which of the returned values belonged to which field.

=head2 remove_content_headers

This will remove all the header fields used to describe the content of a message. All header field names prefixed with C<Content-> fall into this category, as well as C<Allow>, C<Expires> and
C<Last-Modified>. RFC 2616 denotes these fields as I<Entity Header Fields>.

The return value is a new L<HTTP::Headers> object that contains the removed headers only.

=head2 scan

Apply a subroutine to each header field in turn. The callback routine is called with two parameters; the name of the field and a single value (a string). If a header field is multi-valued, then the routine is called once for each value.  The field name passed to the callback routine has case as suggested by HTTP spec, and the headers will be visited in the recommended "Good Practice" order.

Any return values of the callback routine are ignored. The loop can be broken by raising an exception (L<perlfunc/die>), but the caller of scan() would have to trap the exception itself.

=head2 server

The server header field contains information about the software being used by the originating server program handling the request.

=head2 user_agent

This header field is used in request messages and contains information about the user agent originating the request.  I<E.g.>:

    $h->user_agent( 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:93.0) Gecko/20100101 Firefox/93.0' );

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
