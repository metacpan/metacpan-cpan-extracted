package Zonemaster::LDNS::RR::DNSKEY;

use strict;
use warnings;

use parent 'Zonemaster::LDNS::RR';

sub keysize {
    my ( $self ) = @_;

    my $algo = $self->algorithm;
    my $data = $self->keydata;

    # RSA variants
    if ( $algo == 1 || $algo == 5 || $algo == 7 || $algo == 8 || $algo == 10 ) {

        # Read first byte
        return -1
          if length $data < 1;
        my $byte = unpack( "c1", $data );

        my $remaining;
        if ( $byte > 0 ) {
            $remaining = length( $data ) - 1 - $byte;
        }
        else {
            # Read bytes 1 and 2 as big-endian
            return -1
              if length $data < 3;
            my $short = unpack( "x1s>1", $data );

            $remaining = length( $data ) - 3 - $short;
        }

        if ( $remaining < 0 ) {
            return -1;
        }
        else {
            return 8 * $remaining;
        }
    }

    # DSA variants
    elsif ( $algo == 3 || $algo == 6 ) {

        # Read first byte (the T value)
        return -1
          if length $data < 1;
        return unpack( "c1", $data );
    }

    # Diffie-Hellman
    elsif ( $algo == 2 ) {

        # Read bytes 4 and 5 as big-endian
        return -1
          if length $data < 6;
        return unpack( "x4s>1", $data );
    }

    # No idea what this is
    else {
        return 0;
    }
}

1;

=head1 NAME

Zonemaster::LDNS::RR::DNSKEY - Type DNSKEY record

=head1 DESCRIPTION

A subclass of L<Zonemaster::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item flags()

Returns the flag field as a number.

=item protocol()

Returns the protocol number.

=item algorithm()

Returns the algorithm number.

=item keydata()

Returns the cryptographic key in binary form.

=item ds($hash)

Returns a L<Zonemaster::LDNS::RR::DS> record matching this key. The argument must be one of the strings 'sha1', 'sha256', 'sha384' or 'gost'. GOST may not
be available, depending on how you ldns library was compiled.

=item keysize()

The size of the key stored in the record. For RSA variants, it's the length in bits of the prime number. For DSA variants, it's the key's "T" value
(see RFC2536). For DH, it's the value of the "prime length" field (and probably useless, since DH keys can't have signature records).
If there is insufficient data in the public key field to calculate the key size, C<-1> is returned.

=back
