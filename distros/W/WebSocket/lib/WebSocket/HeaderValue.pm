##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/HeaderValue.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/30
## Modified 2021/09/30
## You can use, copy, modify and  redistribute  this  package  and  associated
## files under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::HeaderValue;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.1.0';
    use overload (
        '""' => 'as_string',
        fallback => 1,
    );
    our $QUOTE_REGEXP = qr/([\\"])/;
    #
    # RegExp to match type in RFC 7231 sec 3.1.1.1
    #
    # media-type = type "/" subtype
    # type       = token
    # subtype    = token
    #
    our $TYPE_REGEXP  = qr/^[!#$%&'*+.^_`|~0-9A-Za-z-]+\/[!#$%&'*+.^_`|~0-9A-Za-z-]+$/;
    our $TOKEN_REGEXP = qr/^[!#$%&'*+.^_`|~0-9A-Za-z-]+$/;
    our $TEXT_REGEXP  = qr/^[\u000b\u0020-\u007e\u0080-\u00ff]+$/;
};

sub init
{
    my $self  = shift( @_ );
    my $value = shift( @_ );
    return( $self->error( "No value provided." ) ) if( !length( $value ) );
    $self->{original} = '';
    $self->{value}    = $value;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{params} = {};
    return( $self );
}

sub new_from_multi
{
    my $self = shift( @_ );
    my $s    = shift( @_ );
    return( $self->error( 'Header value is required' ) ) if( !defined( $s ) || !length( $s ) );
    my $sep  = @_ ? shift( @_ ) : ';';
    my @parts = ();
    my $i = 0;
    foreach( split( /(\\.)|\,/, $s ) ) 
    {
        defined( $_ ) ? do{ $parts[$i] .= $_ } : do{ $i++ };
    }
    my $res = $self->new_array;
    for( my $j = 0; $j < scalar( @parts ); $j++ )
    {
        my $o = $self->new_from_header( $parts[$j] );
        return( $self->pass_error ) if( !defined( $o ) );
        $res->push( $o );
    }
    return( $res );
}

sub new_from_header
{
    my $self = shift( @_ );
    my $s    = shift( @_ );
    return( $self->error( 'Header value is required' ) ) if( !defined( $s ) || !length( $s ) );
    my $sep  = @_ ? shift( @_ ) : ';';
    my @parts = ();
    my $i = 0;
    foreach( split( /(\\.)|$sep/, $s ) ) 
    {
        defined( $_ ) ? do{ $parts[$i] .= $_ } : do{ $i++ };
    }
    # $self->message( 3, "Field parts are: ", sub{ $self->dumper( \@parts ) } );
    my $header_val = shift( @parts );
    my $obj = WebSocket::HeaderValue->new( $header_val );

    foreach my $frag ( @parts )
    {
        $frag =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
        my( $attribute, $value ) = split( /[[:blank:]\h]*\=[[:blank:]\h]*/, $frag, 2 );
        # $self->message( 3, "\tAttribute is '$attribute' and value '$value'. Fragment processed was '$frag'" );
        $value =~ s/^\"|\"$//g;
        # Check character string and length. Should not be more than 255 characters
        # http://tools.ietf.org/html/rfc1341
        # http://www.iana.org/assignments/media-types/media-types.xhtml
        # Won't complain if this does not meet our requirement, but will discard it silently
        if( $attribute =~ /^[a-zA-Z][a-zA-Z0-9\_\-]+$/ && CORE::length( $attribute ) <= 255 )
        {
            if( $value =~ /^[a-zA-Z][a-zA-Z0-9\_\-]+$/ && CORE::length( $value ) <= 255 )
            {
                $obj->params( lc( $attribute ) => $value );
            }
        }
    }
    return( $obj );
}

sub as_string
{
    my $self = shift( @_ );
    if( !defined( $self->{original} ) || !length( $self->{original} ) )
    {
        my $string = '';
        if( defined( $self->{value} ) && length( $self->{value} ) )
        {
            if( $self->{value} !~ /^$TYPE_REGEXP$/ )
            {
                return( $self->error( "Invalid value \"$self->{value}\"" ) );
            }
            $string = $self->{value};
        }

        # Append parameters
        # if( $self->{params} && ref( $self->{params} ) eq 'HASH' )
        if( $self->params->length )
        {
            my $params = $self->params->keys->sort;
            for( my $i = 0; $i < scalar( @$params ); $i++ )
            {
                if( $params->[$i] !~ /^$TOKEN_REGEXP$/ )
                {
                    return( $self->error( "Invalid parameter name: \"" . $params->[$i] . "\"" ) );
                }
                if( length( $string ) > 0 )
                {
                    $string .= '; ';
                }
                $string .= $params->[$i] . '=' . $self->qstring( $self->params->get( $params->[$i] ) );
            }
        }
        $self->{original} = $string;
    }
    return( $self->{original} );
}

sub original { return( shift->_set_get_scalar_as_object( 'original', @_ ) ); }

sub params { return( shift->_set_get_hash_as_mix_object( 'params', @_ ) ); }

sub qstring
{
    my $self = shift( @_ );
    my $str  = shift( @_ );

    # no need to quote tokens
    if( $str =~ /^$TOKEN_REGEXP$/ )
    {
        return( $str );
    }

    if( length( $str ) > 0 && $str !~ /^$TEXT_REGEXP$/ )
    {
        return( $self->error( 'Invalid parameter value' ) );
    }
    
    $str =~ s/$QUOTE_REGEXP/\\$1/g;
    return( '"' . $str . '"' );
}

sub reset
{
    my $self = shift( @_ );
    $self->{original} = '';
    return( $self );
}

sub value { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

WebSocket::HeaderValue - WebSocket Client & Server

=head1 SYNOPSIS

    use WebSocket::HeaderValue;
    my $hv = WebSocket::HeaderValue->new( 'foo' ) || die( WebSocket::HeaderValue->error, "\n" );
    my $hv = WebSocket::HeaderValue->new( 'foo', bar => 2 ) || die( WebSocket::HeaderValue->error, "\n" );
    print( "SomeHeader: $hv\n" );
    # will produce:
    SomeHeader: foo; bar=2

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a class to parse and handle HTTP header values in accordance with L<rfc2616|https://datatracker.ietf.org/doc/html/rfc2616#section-4.2>

The object has stringification capability. For this see L</as_string>

=head1 CONSTRUCTORS

=head2 new

Takes a header value, and optionally an hash or hash reference of parameters and this returns the object.

=head2 new_from_header

Takes a header value such as C<food; bar=2> and this will parse it and return a new L<WebSocket::HeaderValue> object.

=head2 new_from_multi

Takes a header value that contains potentially multiple values and this returns an array object (L<Module::Generic::Array>) of L<WebSocket::HeaderValue> objects.

=head1 METHODS

=head2 as_string

Returns the object as a string suitable to be added in a n HTTP header.

=head2 original

Cache value of the object stringified. It could also be set during object instantiation to provide the original header value.

    my $hv = WebSocket::HeaderValue->new( 'foo', original => 'foo; bar=2' ) || 
        die( WebSocket::HeaderValue->error );

=head2 params

Set or get an hash object (L<Module::Generic::Hash>) of parameters.

=head2 qstring

Provided with a string and this returns a quoted version, if necessary.

=head2 reset

Remove the cached version of the stringification, i.e. set the object property C<original> to an empty string.

=head2 value

Set or get the main header value. For example, in the case of C<foo; bar=2>, the main value here is C<foo>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
