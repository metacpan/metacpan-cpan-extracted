# This will test through a standard workflow / use-case to read an entry from KeePass
#
use 5.012; # strict, //
use warnings;
use Test::More;
use MIME::Base64;

use WWW::KeePassHttp;

my @nonces = map { sleep(1); [WWW::KeePassHttp::generate_nonce] } 1 .. 2;
is length($_->[1]), 24, "is valid: " . $_->[1] for @nonces;
is encode_base64($_->[0],''), $_->[1], "value and encoded value match for " . $_->[1] for @nonces;
isnt $nonces[0][1], $nonces[1][1], 'unique';

my $nonce_only = WWW::KeePassHttp::generate_nonce;
is length($nonce_only), 16, "is valid nonce-only";

done_testing();
