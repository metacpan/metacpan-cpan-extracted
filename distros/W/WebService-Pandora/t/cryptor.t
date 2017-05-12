use strict;
use warnings;

use Test::More tests => 10;

use WebService::Pandora::Cryptor;

my $cryptor = WebService::Pandora::Cryptor->new( encryption_key => 'mycryptkey',
                                                 decryption_key => 'mycryptkey' );

my $data = "encryptmeplz";

# make sure we can encrypt data properly
my $encrypted = $cryptor->encrypt( $data );
is( $encrypted, '68d61496323a99c737a3c9a28d704c00', 'encrypt' );

# make sure decrypting the encrypted data is the original
my $decrypted = $cryptor->decrypt( $encrypted );
is( $decrypted, 'encryptmeplz', 'decrypt' );

# test out not providing any data to decrypt/encrypt
$encrypted = $cryptor->encrypt();
is( $encrypted, undef, 'undefined encrypt' );
is( $cryptor->error(), 'A string of data to encrypt must be given.', 'encrypt error string' );

$decrypted = $cryptor->decrypt();
is( $decrypted, undef, 'undefined decrypt' );
is( $cryptor->error(), 'A string of data to decrypt must be given.', 'decrypt error string' );

# test out not providing encryption/decryption keys
$cryptor = WebService::Pandora::Cryptor->new();

$encrypted = $cryptor->encrypt( $data );
is( $encrypted, undef, 'undefined encrypt' );
is( $cryptor->error(), 'An encryption_key must be provided to the constructor.', 'encrypt error string' );

$decrypted = $cryptor->decrypt( '68d61496323a99c737a3c9a28d704c00' );
is( $decrypted, undef, 'undefined decrypt' );
is( $cryptor->error(), 'A decryption_key must be provided to the constructor.', 'decrypt error string' );
