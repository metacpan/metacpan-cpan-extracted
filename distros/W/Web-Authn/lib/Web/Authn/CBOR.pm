##----------------------------------------------------------------------------
## WebAuthn - ~/lib/Web/Authn/CBOR.pm
## Version v0.2.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/09/09
## Modified 2026/09/12
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Web::Authn::CBOR;
BEGIN
{
    use v5.16.0;
    use strict;
    use warnings;
    warnings::register_categories( 'Web::Authn' );
    use vars qw( $VERSION );
    use overload ();
    use Scalar::Util ();
    use Web::Authn::Exception;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

# Minimal CTAP2-oriented CBOR codec. Maps keep integer keys as Perl integers.
# decode() returns ($value, $bytes_consumed).

sub decode
{
    my $bytes = shift( @_ );
    unless( defined( $bytes ) )
    {
        _err( 'empty CBOR input' );
    }
    my( $val, $off ) = _decode( $bytes, 0 );
    return( wantarray ? ( $val, $off ) : $val );
}

sub encode
{
    my $val = shift( @_ );
    return( _encode( $val ) );
}

sub encode_bstr
{
    my $s = shift( @_ );
    return( _uint( 2, length( $s ) ) . $s );
}

sub _addl
{
    my( $buf, $off, $ai ) = @_;
    return( $ai, $off ) if( $ai < 24 );
    if( $ai == 24 )
    {
        unless( $off < length( $buf ) )
        {
            _err( 'truncated' );
        }
        return( unpack( 'C', substr( $buf, $off, 1 ) ), $off + 1 );
    }
    elsif( $ai == 25 )
    {
        unless( $off + 2 <= length( $buf ) )
        {
            _err( 'truncated' );
        }
        return( unpack( 'n', substr( $buf, $off, 2 ) ), $off + 2 );
    }
    elsif( $ai == 26 )
    {
        unless( $off + 4 <= length( $buf ) )
        {
            _err( 'truncated' );
        }
        return( unpack( 'N', substr( $buf, $off, 4 ) ), $off + 4 );
    }
    elsif( $ai == 27 )
    {
        unless( $off + 8 <= length( $buf ) )
        {
            _err( 'truncated' );
        }
        my( $hi, $lo ) = unpack( 'NN', substr( $buf, $off, 8 ) );
        return( $hi * 2 ** 32 + $lo, $off + 8 );
    }
    _err( "indefinite or reserved additional info $ai" );
}

sub _decode
{
    my( $buf, $off ) = @_;
    unless( $off < length( $buf ) )
    {
        _err( 'truncated' );
    }
    my $ib = unpack( 'C', substr( $buf, $off, 1 ) );
    my $major = $ib >> 5;
    my $ai    = $ib & 31;
    $off++;

    my( $n, $noff ) = _addl( $buf, $off, $ai );
    $off = $noff;

    if( $major == 0 )
    {
        return( $n, $off );
    }
    elsif( $major == 1 )
    {
        return( ( -1 - $n ), $off );
    }
    elsif( $major == 2 )
    {
        unless( $off + $n <= length( $buf ) )
        {
            _err( 'truncated bstr' );
        }
        return( substr( $buf, $off, $n ), $off + $n );
    }
    elsif( $major == 3 )
    {
        unless( $off + $n <= length( $buf ) )
        {
            _err( 'truncated tstr' );
        }
        return( substr( $buf, $off, $n ), $off + $n );
    }
    elsif( $major == 4 )
    {
        my @arr;
        for( 1 .. $n )
        {
            my( $v, $o ) = _decode( $buf, $off );
            push( @arr, $v );
            $off = $o;
        }
        return( \@arr, $off );
    }
    elsif( $major == 5 )
    {
        my %map;
        for( 1 .. $n )
        {
            my( $k, $o1 ) = _decode( $buf, $off );
            my( $v, $o2 ) = _decode( $buf, $o1 );
            if( exists( $map{ $k } ) )
            {
                _err( 'duplicate map key' );
            }
            $map{ $k } = $v;
            $off = $o2;
        }
        return( \%map, $off );
    }
    elsif( $major == 6 )
    {
        # Tag: decode tagged value and ignore tag number
        my( $v, $o ) = _decode( $buf, $off );
        return( $v, $o );
    }
    elsif( $major == 7 )
    {
        # false as 0
        if( $ai == 20 )
        {
            return( 0, $off );
        }
        # true as 1
        elsif( $ai == 21 )
        {
            return( 1, $off );
        }
        # null
        elsif( $ai == 22 )
        {
            return( undef, $off );
        }
        # undefined
        elsif( $ai == 23 )
        {
            return( undef, $off );
        }
        _err( "unsupported simple/float ai=$ai" );
    }
    _err( "unsupported major $major" );
}

sub _encode
{
    my $v = shift( @_ );
    return( _head( 7, 22 ) ) unless( defined( $v ) );
    my $r = Scalar::Util::reftype( $v ) || '';
    if( !$r )
    {
        if( $v =~ /^-?\d+\z/ )
        {
            return( $v >= 0 ? _uint( 0, $v ) : _uint( 1, -1 - $v ) );
        }
        # treat as text if utf8-looking printable, else bytes
        if( $v =~ /[^\x00-\x7F]/ || $v =~ /^[\x20-\x7E]*\z/ )
        {
            return( _uint( 3, length( $v ) ) . $v );
        }
        return( _uint( 2, length( $v ) ) . $v );
    }
    elsif( $r eq 'SCALAR' && !Scalar::Util::blessed( $v ) )
    {
        # \bytes for explicit bstr
        my $s = $$v;
        return( _uint( 2, length( $s ) ) . $s );
    }
    elsif( $r eq 'ARRAY' )
    {
        my $out = _uint( 4, scalar( @$v ) );
        $out .= _encode( $_ ) for( @$v );
        return( $out );
    }
    elsif( $r eq 'HASH' )
    {
        my @keys = sort{ _key_sort( $a, $b ) } keys( %$v );
        my $out = _uint( 5, scalar( @keys ) );
        foreach my $k ( @keys )
        {
            my $nk = ( $k =~ /^-?\d+\z/ ) ? 0 + $k : $k;
            $out .= _encode( $nk );
            $out .= _encode( $v->{ $k } );
        }
        return( $out );
    }
    elsif( Scalar::Util::blessed( $v ) && overload::Method( $v, '""' ) )
    {
        return( _encode( $v . '' ) );
    }
    _err( "cannot encode $r" );
}

sub _err { Web::Authn::Exception::InvalidStructure->throw( "CBOR: $_[0]" ) }

sub _head
{
    my( $major, $ai ) = @_;
    return( pack( 'C', ( $major << 5 ) | $ai ) );
}

sub _key_sort
{
    my( $a, $b ) = @_;
    my $an = $a =~ /^-?\d+\z/;
    my $bn = $b =~ /^-?\d+\z/;
    return( $a <=> $b ) if( $an && $bn );
    return( $a cmp $b );
}

sub _uint
{
    my( $major, $n ) = @_;
    return( _head( $major, $n ) ) if( $n < 24 );
    return( _head( $major, 24 ) ) . pack( 'C', $n ) if( $n < 256 );
    return( _head( $major, 25 ) ) . pack( 'n', $n ) if( $n < 65536 );
    return( _head( $major, 26 ) ) . pack( 'N', $n ) if( $n < 2 ** 32 );
    my $hi = int( $n / 2 ** 32 );
    my $lo = $n - $hi * 2 ** 32;
    return( _head( $major, 27 ) . pack( 'NN', $hi, $lo ) );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Web::Authn::CBOR - Small CTAP2-oriented CBOR codec

=head1 SYNOPSIS

    my $bin = Web::Authn::CBOR::encode({ 1 => 2, 3 => -7, -2 => \$bytes });
    my ($value, $consumed) = Web::Authn::CBOR::decode($bin);

=head1 DESCRIPTION

WebAuthn attestation objects, authenticator data public keys, and attestation statements are CBOR. This codec covers the subset CTAP2 uses: unsigned and negative integers, byte strings, text strings, arrays, maps (integer or string keys), and tags (decoded, tag number discarded).

Duplicate map keys are rejected, as CTAP2 requires.

=head1 FUNCTIONS

=head2 decode

    my $value = Web::Authn::CBOR::decode( $bin );
    my( $value, $consumed ) = Web::Authn::CBOR::decode( $bin );

Decodes a CBOR blob. In list context it returns C<($value, $bytes_consumed)>; in scalar context it returns only the value. Pass the raw CBOR bytes. The function dies with L<Web::Authn::Exception::InvalidStructure> on truncated or illegal input.

=head2 encode

    my $bin = Web::Authn::CBOR::encode({ 1 => 2, 3 => -7, -2 => \$bytes });

Encodes a Perl structure to CBOR. Pass an undef, an integer, a string, a scalar reference (to force a major-type-2 byte string), an array, or a hash. Plain strings that look printable are emitted as text strings. Blessed objects that overload C<""> are stringified first.

=head2 encode_bstr

    my $bin = Web::Authn::CBOR::encode_bstr( $octets );

Encodes raw octets as a CBOR major-type-2 byte string. Pass the byte string to wrap.

=head1 THREAD & PROCESS SAFETY

This module is designed to be fully thread-safe and process-safe, ensuring data integrity across Perl ithreads and mod_perl’s threaded Multi-Processing Modules (MPMs) such as Worker or Event.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

RFC 8949, FIDO CTAP2 canonical CBOR, L<Web::Authn::Parse>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
