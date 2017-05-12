package GCrypt;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = ();

our @EXPORT = ();

our $VERSION = '0.3';

require XSLoader;
XSLoader::load('GCrypt', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

GCrypt - Perl interface to the GNU Crypto library

=head1 SYNOPSIS

  use GCrypt;

  $cipher = new GCrypt::Cipher('aes', 'cbc');

  $cipher->setkey('a secret');

  $cipher->setiv('init vector');

  $ciphertext = $cipher->encrypt('plaintext');

  $plaintext  = $cipher->decrypt($ciphertext);

=head1 ABSTRACT

GCrypt is the Perl interface to the same-named LGPL'd library of
cryptographic functions. Currently only symmetric
encryption/decryption is supported by this interface.

=head1 DESCRIPTION

Note that if you are still confused by the crypto terminology, head
over to L</BACKGROUND> first.

Symmetric encryption/decryption is done by first obtaining a Cipher object:

$cipher = new GCrypt::Cipher(I<ALGORITHM>[, I<MODE>[, I<FLAGS>]]);

I<ALGORITHM> is a string naming the algorithm. At the time of writing,
the following choices are available:

=over

=item B<3des> Triple DES, 112 bit key

=item B<aes> The Advanced Encryption Standard, a.k.a. Rijndael, 128 bit key

=item B<aes192> AES with 192 bit key

=item B<aes256> AES with 256 bit key

=item B<blowfish>

=item B<cast5>

=item B<des> Date Encryption Standard, 56 bit key, too short to thwart
brute-forcing

=item B<twofish> Successor of Blowfish, 256 bit key

=item B<arcfour> stream cipher

=back

I<MODE> is a string specifying one of the following
encryption/decryption modes:

=over

=item B<stream> only possible mode for stream ciphers

=item B<ecb> don't use an IV, encrypt each block on it's own

=item B<cbc> the current ciphertext block is encryption of current plaintext block xor-ed with last ciphertext block

=item B<cfb> the current ciphertext block is the current plaintext
block xor-ed with the current keystream block, which is the encryption
of the last ciphertext block

=item B<ofb> the current ciphertext block is the current plaintext
block xor-ed with the current keystream block, which is the encryption
of the last keystream block

=back

Between calls the "last block" is stored in the IV.

If no mode is specified B<cbc> is selected for block ciphers, and
B<stream> for stream ciphers.

I<FLAGS> is a string containing zero or more flags seperated by a pipe
(C<|>). The possible flags are:

=over

=item B<secure> all data associated with this cipher will be put into
non-swappable storage, if possible.

=item B<enable_sync> enable the CFB sync operation.

$cipher->setkey(I<KEY>)

Encryption and decryption operations will use I<KEY> until a different
one is set. If I<KEY> is shorter than the cipher's keylen (see the
C<keylen> method) it will be zero-padded, if it is longer it will be
truncated.

$cipher->setiv([I<IV>])

Set the initialisation vector to I<IV> for the next encrypt/decrypt operation.
If I<IV> is missing a "standard" IV of all zero is used. The same IV is set in
newly created cipher objects.

$cipher->encrypt(I<PLAINTEXT>)

This method encrypts I<PLAINTEXT> with $cipher, returning the
corresponding ciphertext. Null byte padding is automatically appended
if I<PLAINTEXT>'s length is not evenly divisible by $cipher's block
size.

$cipher->decrypt(I<CIPHERTEXT>)

The counterpart to encrypt, decrypt takes a I<CIPHERTEXT> and produces the
original plaintext (given that the right key was used, of course).

$cipher->keylen()

Returns the number of bytes of keying material this cipher needs.

$cipher->blklen()

As their name implies, block ciphers operate on blocks of data. This
method returns the size of this blocks in bytes for this particular
cipher. For stream ciphers C<1> is returned, since this implementation
does not support feeding less than a byte into the cipher.

$cipher->sync()

Apply the CFB sync operation.

=head2 EXPORT

None, as the interface is object-oriented.

=head1 BACKGROUND

I<Symmetric ciphers> are basically black boxes that you prime with a
I<key>. Then you can feed them I<plaintext>, which they will munch
into the encrypted result called I<ciphertext>. They work into the
other direction as well (hence the "symmetric"), taking I<ciphertext>
as input and reconstructing it into I<plaintext>.

There are two kind of symmetric ciphers: I<block ciphers> like B<AES>
take their input in chunks of a fixed size (e.g. 256 bit), producing a
corresponding block of output (usually of the same size) for each such
chunk. If the plaintext length is not evenly divisible by the block
size, I<padding> (normally a suitable number of null bytes) is
appended to the end. This has to be removed again after decryption.

I<stream ciphers> take input one bit at a time (you can think of them
as special block ciphers with the smallest possible block size), and
produce a corresponding output bit. Their advantage is that each bit
of plaintext can be immediately encrypted as soon as it is available
(think: encryption of an audio stream).

=head1 SEE ALSO

The gcrypt manual should be available via C<info gcrypt> from the
shell or C<C-h i g (gcrypt)> from inside emacs.

=head1 AUTHOR

Robert Bihlmeyer, E<lt>robbe@orcus.priv.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Robert Bihlmeyer

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
