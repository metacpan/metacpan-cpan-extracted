package WWW::Suffit::RSA;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::RSA - The RSA encryption and signing subclass

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use WWW::Suffit::RSA;

    my $rsa = WWW::Suffit::RSA->new;

    $rsa->keygen(2048);
    my $private_key = $rsa->private_key;
    my $public_key = $rsa->public_key;

    my $b64_cipher_text = $rsa->encrypt("test");
    my $plain_text = $rsa->decrypt($b64_cipher_text);

    my $signature = $rsa->sign("Text", 256) or die $rsa->error;
    $rsa->verify("Text", $signature, 256) or die $rsa->error || "Incorrect signature";

=head1 DESCRIPTION

The RSA encryption and signing subclass

This module based on L<Crypt::OpenSSL::RSA>

=head1 METHODS

L<WWW::Suffit::RSA> inherits all of the properties and methods from L<Mojo::Base> and implements the following new ones.

=head2 decrypt

    my $plain_text = $rsa->decrypt($b64_cipher_text);

Decrypt a base64 short "string" to plain text

=head2 encrypt

    my $b64_cipher_text = $rsa->encrypt("test");

Encrypt a short "string" using the public key and returns base64 string

=head2 error

    $rsa->error($new_error);
    my $error = $rsa->error;

Sets/gets the error string

=head2 keygen

    $rsa->keygen( $key_size );
    my $public_key = $rsa->public_key;
    my $private_key = $rsa->private_key;

Create a new private/public key pair (the public exponent is 65537).
The argument is the key size, default is 2048

=head2 private_key

The RSA private key to be used in edcoding an asymmetrically signed data

=head2 public_key

The RSA public key to be used in decoding an asymmetrically signed data

=head2 sign

    my $signature = $rsa->sign($string, $size);

Returns the RSA signature for the given size and string.
The L</private_key> attribute is used as the private key.
The result is not yet base64 encoded.
This method is provided mostly for the purposes of subclassing.

=head2 verify

    my $bool = $rsa->verify($string, $signature, $size);

Returns true if the given RSA size algorithm validates the given string and signature.
The L</public_key> attribute is used as the public key.
This method is provided mostly for the purposes of subclassing.

=head1 DEPENDENCIES

L<Crypt::OpenSSL::RSA>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojolicious>, L<Crypt::OpenSSL::RSA>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = "1.00";

use Mojo::Base -base;
use Mojo::Util qw/b64_encode b64_decode/;
use Crypt::OpenSSL::RSA;

use constant {
    KEY_SIZE        => 2048,
    SHA_SIZE        => 256,
    KEY_SIZES_MAP   => [512, 1024, 2048, 4096],
    SHA_SIZES_MAP   => [224, 256, 384, 512],
};

has 'key_size'      => KEY_SIZE; # RSA key size
has 'sha_size'      => SHA_SIZE; # RSA SHA size
has 'private_key'   => ''; # RSA private key
has 'public_key'    => ''; # RSA public key
has 'error'         => ''; # Error string

sub keygen {
    my $self = shift;
    my $key_size = shift || $self->key_size || KEY_SIZE;
    $self->error(''); # Flush error string first

    # Correct key size
    $key_size = KEY_SIZE
        unless grep {$_ == $key_size} @{(KEY_SIZES_MAP)};

    my $rsa = Crypt::OpenSSL::RSA->generate_key($key_size);
    my $private_key = $rsa->get_private_key_string;
       $self->private_key($private_key);
    my $public_key = $rsa->get_public_key_string;
       $self->public_key($public_key);

    return $self;
}
sub encrypt {
    my ($self, $text) = @_;
    $self->error(''); # Flush error string first
    $self->error('The text for encrypting is not specified') && return unless $text;

    # Get RSA public key
    my $public_key = $self->public_key // '';
    $self->error('Public key not specified') && return unless length $public_key;

    # Create RSA object
    my $rsa_pub = eval {Crypt::OpenSSL::RSA->new_public_key($public_key)};
    if ($@) {
        chomp $@;
        $self->error($@);
        return;
    }

    return b64_encode($rsa_pub->encrypt($text), '');
}
sub decrypt {
    my ($self, $cipher) = @_;
    $self->error(''); # Flush error string first
    $self->error('The ciphertext for decryption is not specified') && return unless $cipher;

    # Get RSA private key
    my $private_key = $self->private_key // '';
    $self->error('Private key not specified') && return unless length $private_key;

    # Create RSA object
    my $rsa_priv = Crypt::OpenSSL::RSA->new_private_key($private_key);

    my $plaintext = eval {$rsa_priv->decrypt(b64_decode($cipher))} // '';
    if ($@) {
        chomp $@;
        $self->error($@);
        return;
    }

    return $plaintext;
}
sub sign {
    my ($self, $text, $size) = @_;
    $size ||= $self->sha_size || SHA_SIZE;
    $self->error(''); # Flush error string first

    # Get RSA private key
    my $private_key = $self->private_key // '';
    $self->error('Private key not specified') && return unless length $private_key;

    # Correct sha size
    $size = SHA_SIZE
        unless grep {$_ == $size} @{(SHA_SIZES_MAP)};

    # Create RSA object
    my $rsa_priv = Crypt::OpenSSL::RSA->new_private_key($private_key);

    my $m = $rsa_priv->can("use_sha${size}_hash");
    $self->error('Unsupported SHA hash size') && return unless $m;
    $rsa_priv->$m; # Switch to alg

    # Sign!
    return b64_encode($rsa_priv->sign($text), '');
}
sub verify {
    my ($self, $text, $signature, $size) = @_;
    $size ||= $self->sha_size || SHA_SIZE;
    $self->error(''); # Flush error string first

    # Get RSA public key
    my $public_key = $self->public_key // '';
    $self->error('Public key not specified') && return unless length $public_key;

    # Correct sha size
    $size = SHA_SIZE
        unless grep {$_ == $size} @{(SHA_SIZES_MAP)};

    # Create RSA object
    my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($public_key);

    my $m = $rsa_pub->can("use_sha${size}_hash");
    $self->error('Unsupported SHA hash size') && return unless $m;
    $rsa_pub->$m; # Switch to alg

    # Verify!
    return $rsa_pub->verify($text, b64_decode($signature)) ? 1 : 0;
}

1;

__END__
