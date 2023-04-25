##----------------------------------------------------------------------------
## WebSocket Client & Server - ~/lib/WebSocket/Frame.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/09/16
## Modified 2021/09/16
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package WebSocket::Frame;
BEGIN
{
    use strict;
    use warnings;
    use WebSocket qw( :all );
    use parent qw( WebSocket );
    use vars qw( $VERSION $MAX_PAYLOAD_SIZE $MAX_FRAGMENTS_AMOUNT $TYPES );
    use Config;
    use Encode ();
    use Scalar::Util qw( readonly );
    use Nice::Try;
    use constant MAX_RAND_INT       => 2**32;
    use constant MATH_RANDOM_SECURE => eval( "require Math::Random::Secure;" );
    use constant SUPPORT_64BITS     => ( ( $Config{use64bitint} // '' ) eq 'define' || !( $Config{ivsize} <= 4 || $Config{longsize} < 8 || $] < 5.010 ) );
    use constant RSV1               => chr(4 << 4);
    use constant RSV2               => chr(2 << 4);
    use constant RSV3               => chr(1 << 4);

    our $MAX_PAYLOAD_SIZE     = 65536;
    our $MAX_FRAGMENTS_AMOUNT = 128;

    our $TYPES = 
    {
        continuation => 0x00,
        text         => 0x01,
        binary       => 0x02,
        ping         => 0x09,
        pong         => 0x0a,
        close        => 0x08
    };
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    my $buffer;
    if( @_ && 
        ref( $_[0] ) ne 'HASH' && 
        (
            ( @_ == 2 && ref( $_[1] ) eq 'HASH' ) ||
            ( @_ % 2 )
        ) )
    {
        $buffer = shift( @_ );
    }
    $self->{buffer}                 = $buffer;
    # fin value must be undef
    $self->{fin}                    = undef;
    $self->{fragments}              = [];
    $self->{max_fragments_amount}   = $MAX_FRAGMENTS_AMOUNT unless( length( $self->{max_fragments_amount} ) );
    $self->{max_payload_size}       = $MAX_PAYLOAD_SIZE unless( length( $self->{max_payload_size} ) );
    $self->{opcode}                 = undef;
    $self->{rsv}                    = [];
    $self->{type}                   = '';
    $self->{version}                = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->version( WEBSOCKET_DRAFT_VERSION_DEFAULT ) unless( $self->version );
    $self->{buffer} //= '';
    if( Encode::is_utf8( $self->{buffer} ) )
    {
        $self->{buffer} = Encode::encode( 'UTF-8', $self->{buffer} );
    }
    if( defined( $self->{type} ) && defined( $TYPES->{ $self->{type} } ) )
    {
        $self->opcode( $TYPES->{ $self->{type} } );
    }
    return( $self );
}

sub append
{
    my $self = shift( @_ );
    return unless( defined( $_[0] ) );

    $self->buffer->append( $_[0] );
    $_[0] = '' unless( readonly( $_[0] ) );
    return( $self );
}

sub buffer { return( shift->_set_get_scalar_as_object( 'buffer', @_ ) ); }

sub fin
{
    my $self = shift( @_ );
    $self->{fin} = shift( @_ ) if( @_ );
    return( defined( $self->{fin} ) ? $self->{fin} : 1 );
}

sub fragments { return( shift->_set_get_array_as_object( 'fragments', @_ ) ); }

sub is_binary       { return( shift->opcode == 2 ); }

sub is_close        { return( shift->opcode == 8 ); }

sub is_continuation { return( shift->opcode == 0 ); }

sub is_ping         { return( shift->opcode == 9 ); }

sub is_pong         { return( shift->opcode == 10 ); }

sub is_text         { return( shift->opcode == 1 ); }

sub masked { return( shift->_set_get_scalar( 'masked', @_ ) ); }

sub max_fragments_amount { return( shift->_set_get_number( 'max_fragments_amount', @_ ) ); }

sub max_payload_size { return( shift->_set_get_number( 'max_payload_size', @_ ) ); }

sub next
{
    my $self = shift( @_ );
    my $bytes = $self->next_bytes;
    return( $self->pass_error ) if( !defined( $bytes ) && $self->error );
    return( Encode::decode( 'UTF-8', $bytes ) ) if( $self->is_text );
    return( $bytes );
}

sub next_bytes
{
    my $self = shift( @_ );

    my $v = $self->version;
    if( ( $v->type eq 'hixie' && $v->revision == 75 ) ||
        ( $v->type eq 'hybi'  && $v->revision <= 3 ) )
    {
        if( $self->buffer->replace( qr/^\xff\x00/ => '' ) )
        {
            $self->opcode(8);
            return( '' );
        }
        # return unless( ${$self->{buffer}} =~ s/^[^\x00]*\x00(.*?)\xff//s );
        my $rv = $self->buffer->replace( qr/^[^\x00]*\x00(.*?)\xff/s, '' );
        return unless( $rv );
        # return( $1 );
        return( $rv->capture->first );
    }
    return unless( $self->buffer->length >= 2 );

    while( $self->buffer->length )
    {
        my( $first, $second ) = $self->buffer->unpack( 'C2' );

        my $fin  = ( $first & 0b10000000 ) == 0b10000000 ? 1 : 0;

        my $rsv1 = ( $first & 0b01000000 ) == 0b01000000 ? 1 : 0;
        my $rsv2 = ( $first & 0b00100000 ) == 0b00100000 ? 1 : 0;
        my $rsv3 = ( $first & 0b00010000 ) == 0b00010000 ? 1 : 0;
        $self->fin( $fin );
        $self->rsv( [$rsv1, $rsv2, $rsv3] );

        # Opcode
        my $opcode = $first & 0b00001111;
        my $masked = ( $second & 0b10000000 ) >> 7;
        $self->masked( $masked );
        my( $offset, $payload_len ) = ( 2, $second & 0b01111111 );
        if( $payload_len == 126 )
        {
            return unless( $self->buffer->length >= $offset + 2 );
            $payload_len = $self->buffer->substr( $offset, 2 )->unpack( 'n' );
            $offset += 2;
        }
        elsif( $payload_len > 126 )
        {
            return unless( $self->buffer->length >= $offset + 4 );

            my $bits = $self->buffer->substr( $offset, 8 )->split( '' )->map(sub{ CORE::unpack( 'B*', $_ ) })->join( '' );

            # Most significant bit must be 0.
            # And here is a crazy way of doing it %)
            $bits->replace( qr{^.}, 0 );

            # Can we handle 64bit numbers?
            if( SUPPORT_64BITS )
            {
                $payload_len = $bits->pack( 'B*' )->unpack( 'Q>' );
            }
            else
            {
                $bits = $bits->substr(32);
                $payload_len = $bits->pack( 'B*' )->unpack( 'N' );
            }
            $offset += 8;
        }
        
        if( $self->max_payload_size && $payload_len > $self->max_payload_size )
        {
            $self->buffer->empty;
            return( $self->error({ code => WS_MESSAGE_TOO_LARGE, message => "Payload is too big. Deny big message ($payload_len) or increase max_payload_size ($self->{max_payload_size})" }) );
        }

        my $mask;
        if( $self->masked )
        {
            return unless( $self->buffer->length >= $offset + 4 );

            $mask = $self->buffer->substr( $offset, 4 );
            $offset += 4;
        }
        else
        {
        }

        return if( $self->buffer->length < $offset + $payload_len );

        my $payload = $self->buffer->substr( $offset, $payload_len );

        if( $self->masked )
        {
            $payload = $self->_mask( $payload, $mask );
        }

        $self->buffer->substr( 0, $offset + $payload_len, '' );

        # Injected control frame
        if( $self->fragments->length && $opcode & 0b1000 )
        {
            $self->opcode( $opcode );
            return( $payload );
        }

        if( $self->fin )
        {
            if( $self->fragments->length )
            {
                $self->opcode( $self->fragments->shift );
            }
            else
            {
                $self->opcode( $opcode );
            }
            # $payload = join( '', @{$self->{fragments}}, $payload );
            $payload = $self->fragments->join( '', $payload );
            # $self->{fragments} = [];
            $self->fragments->empty;
            return( $payload );
        }
        else
        {
            # Remember first fragment opcode
            if( !$self->fragments->length )
            {
                $self->fragments->push( $opcode );
            }

            $self->fragments->push( $payload );

            if( $self->fragments->length > $self->max_fragments_amount )
            {
                return( $self->error({ code => WS_INTERNAL_SERVER_ERROR, message => "Too many fragments" }) );
            }
        }
    }
    return;
}

# sub opcode { return( shift->_set_get_scalar_as_object( 'opcode', @_ ) ); }
sub opcode
{
    my $self = shift( @_ );
    $self->{opcode} = shift( @_ ) if( @_ );
    return( defined( $self->{opcode} ) ? $self->{opcode} : 1 );
}

sub rsv { return( shift->_set_get_array_as_object( 'rsv', @_ ) ); }

sub supported_types
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( CORE::exists( $TYPES->{ lc( shift( @_ ) ) } ) );
    }
    return( $self->new_array( [sort( keys( %$TYPES ) )] ) );
}

sub to_bytes
{
    my $self = shift( @_ );
    my $v = $self->version;
    if( ( $v->type eq 'hixie' && $v->revision == 75 ) ||
        ( $v->type eq 'hybi'  && $v->revision <= 3 ) )
    {
        if( $self->type && $self->type eq 'close' )
        {
            return( "\xff\x00" );
        }
        return( "\x00" . $self->buffer . "\xff" );
    }

    if( $self->max_payload_size && 
        $self->buffer->length > $self->max_payload_size )
    {
        return( $self->error({ code => WS_MESSAGE_TOO_LARGE, message => "Payload is too big. Send shorter messages or increase max_payload_size" }) );
    }

    my $opcode = $self->opcode;
    my $head = $opcode + ( $self->fin ? 128 : 0 );
    $head |= 0b01000000 if( $self->rsv->first );
    $head |= 0b00100000 if( $self->rsv->second );
    $head |= 0b00010000 if( $self->rsv->third );
    my $string = pack( 'C', $head );

    my $payload_len = $self->buffer->length;
    if( $payload_len <= 125 )
    {
        # 128
        $payload_len |= 0b10000000 if( $self->masked );
        $string .= pack( 'C', $payload_len );
        # $string .= pack( 'C', $self->masked ? ( $payload_len | 128 ) : $payload_len );
    }
    # 65535
    elsif( $payload_len <= 0xffff )
    {
        $string .= pack( 'C', 126 + ( $self->masked ? 128 : 0 ) );
        $string .= pack( 'n', $payload_len );
        # $string .= pack( 'Cn', $self->masked ? (126 | 128) : 126, $payload_len );
    }
    else
    {
        $string .= pack( 'C', 127 + ( $self->masked ? 128 : 0 ) );

        # Shifting by an amount >= to the system wordsize is undefined
        $string .= pack( 'N', $Config{ivsize} <= 4 ? 0 : $payload_len >> 32 );
        $string .= pack( 'N', ( $payload_len & 0xffffffff ) );
        
        # $string .= pack( 'C', $self->masked ? (127 | 128) : 127 );
        # $string .= SUPPORT_64BITS
        #    ? pack( 'Q>', $payload_len )
        #    : pack( 'NN', ( $Config{ivsize} <= 4 ? 0 : $payload_len >> 32 ), $payload_len & 0xffffffff );
    }

    if( $self->masked )
    {
        my $mask = $self->{mask} || (
            MATH_RANDOM_SECURE
                ? Math::Random::Secure::irand( MAX_RAND_INT )
                : int( rand( MAX_RAND_INT ) )
        );
        $mask = pack( 'N', $mask );
        $string .= $mask;
        $string .= $self->_mask( $self->buffer->scalar, $mask );
    }
    else
    {
        $string .= $self->buffer->scalar;
    }
    return( $string );
}

sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }

sub version { return( shift->_set_get_object_without_init( 'version', 'WebSocket::Version', @_ ) ); }

sub _mask
{
    my $self = shift( @_ );
    my( $payload, $mask ) = @_;
    $mask = "$mask" x ( int( length( "$payload" ) / 4 ) + 1 );
    $mask = substr( $mask, 0, length( "$payload" ) );
    $payload = "$payload" ^ $mask;
    return( $payload );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

WebSocket::Frame - WebSocket Frame

=head1 SYNOPSIS

    use WebSocket::Frame;
    # Create frame
    my $frame = WebSocket::Frame->new( '123' );
    $frame->to_bytes;

    # Parse frames
    my $frame = WebSocket::Frame->new;
    $frame->append( $some_data );
    $f->next; # get next message
    $f->next; # get another next message

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Construct or parse a WebSocket frame.

=head1 CONSTRUCTOR

=head2 C<new>

    # same as (buffer => 'data')
    WebSocket::Frame->new( 'data' );
    WebSocket::Frame->new( buffer => 'data', type => 'close' );

Create a new L<WebSocket::Frame> instance. Automatically detect if the passed data is a Perl string (UTF-8 flag) or bytes.

When called with more than one arguments, it takes the following named arguments (all of them are optional).

=over 4

=item C<buffer>

The payload of the frame. It can also be provided as the first argument of the L</new> method.

=item C<fin>

Boolean default to 1. Indicate whether this frame is the last frame of the entire message body

C<fin> flag of the frame. C<fin> flag must be 1 in the ending frame of fragments.

=item C<masked>

Boolean default to 0.

If set to true, the frame will be masked.

=item C<opcode>

Default to 1. Operation bit, which defines the type of this frame

The opcode of the frame. If I<type> field is set to a valid string, this field is ignored.

=item C<rsv>

Reserved bit, must be 0, if it is not 0, it is marked as connection failure

=item C<type>

Default to C<text>

The type of the frame. Accepted values are: C<continuation>, C<text>, C<binary>, C<ping>, C<pong>, C<close>

=item C<version>

String. Default to C<draft-ietf-hybi-17>

WebSocket protocol version string. See L<WebSocket> for valid version strings.

=back

=head1 METHODS

=head2 append

    $frame->append( $chunk );

Append a frame chunk.

Beware that this method is B<destructive>. It makes C<$chunk> empty unless C<$chunk> is read-only.

=head2 fin

Indicate whether this frame is the last frame of the entire message body

=head2 fragments

Sets or gets the L<array object|Module::Generic::Array> of payload fragments

=head2 is_binary

Returns true if frame is of binary type, false otherwise.

=head2 is_close

Returns true if frame is of close type, false otherwise.

=head2 is_continuation

Returns true if frame is of continuation type, false otherwise.

=head2 is_ping

Returns true if frame is a ping request, false otherwise.

=head2 is_pong

Returns true if frame is a pong response, false otherwise.

=head2 is_text

Returns true if frame is of text type, false otherwise.

=head2 mask

Indicate whether the carried content needs to be XORed with a mask

=head2 masked

    $masked = $frame->masked;
    $frame->masked(1);

Get or set masking of the frame.

=head2 max_fragments_amount

The maximum fragments allowed.

=head2 max_payload_size

The maximum size of the payload. You may set this to C<0> (but not undef) to disable checking the payload size.

=head2 next

    $frame->append( $some_data );

    $frame->next; # next message

Return the next message as a Perl string (UTF-8 decoded).

=head2 next_bytes

Return the next message as is.

=head2 opcode

    $opcode = $frame->opcode;
    $frame->opcode(8);

Get or set opcode of the frame. Operation bit, which defines the type of this frame.

=head2 rsv

Reserved bit, must be 0, if it is not 0, it is marked as connection failure

=head2 supported_types

Provided a type and this returns true if it is supported, false otherwise. This is case insensitive.

Without any argument, this returns an L<array object|Module::Generic::Array> of supported frame types.

=head2 to_bytes

Construct a WebSocket message.

=head1 CREDITS

Viacheslav Tykhanovskyi for code borrowed.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<WebSocket::Client>, L<WebSocket::Connection>, L<WebSocket::Server>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut

