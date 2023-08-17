use strict;
use warnings;
use Test::More tests => 2;
use XML::Enc;
use MIME::Base64 qw/decode_base64 encode_base64/;

my $xml = <<'XML';
<?xml version="1.0"?>
<foo ID="XML-SIG_1">
    <bar>123</bar>
</foo>
XML

my $encrypter = XML::Enc->new(
    {
        key                 => 't/sign-private.pem',
        cert                => 't/sign-certonly.pem',
        no_xml_declaration  => 1
    }
);

my $encrypted = $encrypter->encrypt($xml);

like($encrypted, qr/EncryptedData/, "Successfully Encrypted");

like($encrypter->decrypt($encrypted), qr/XML-SIG_1/, "Successfully Decrypted");
done_testing;
