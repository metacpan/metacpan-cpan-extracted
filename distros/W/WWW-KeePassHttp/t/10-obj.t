use 5.012; # strict, //
use warnings;
use Test::More tests=>3;
use MIME::Base64;

use WWW::KeePassHttp;

# NOTE: this key is used for testing (it was the key used in the example at https://github.com/pfn/keepasshttp/)
#   it is NOT the value you should use for your key in the real application
#   In a real application, you must generate a 256-bit cryptographically secure key,
#   using something like Math::Random::Secure or Crypt::Random,
#   or use `openssl enc -aes-256-cbc -k secret -P -md sha256 -pbkdf2 -iter 100000`
#       and convert the 64 hex nibbles to a key using pack 'H*', $sixtyfournibbles
my $obj = WWW::KeePassHttp->new(Key => decode_base64('CRyXRbH9vBkdPrkdm52S3bTG2rGtnYuyJttk/mlJ15g='));
isa_ok($obj, 'WWW::KeePassHttp', 'main object');
isa_ok($obj->{ua}, 'HTTP::Tiny', 'user agent object');
isa_ok($obj->{cbc}, 'Crypt::Mode::CBC', 'encryption object');

done_testing();
