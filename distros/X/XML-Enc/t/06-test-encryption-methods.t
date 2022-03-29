use strict;
use warnings;
use Test::More tests => 32;
use XML::Enc;
use MIME::Base64 qw/decode_base64 encode_base64/;
use File::Which;

my $xml = <<'XML';
<?xml version="1.0"?>
<foo ID="XML-SIG_1">
    <bar>123</bar>
</foo>
XML

my @key_methods     = qw/rsa-1_5 rsa-oaep-mgf1p/;
my @data_methods    = qw/aes128-cbc aes192-cbc aes256-cbc tripledes-cbc/;

foreach my $km (@key_methods) {
    foreach my $dm (@data_methods) {
        my $encrypter = XML::Enc->new(
            {
                key                 => 't/sign-private.pem',
                cert                => 't/sign-certonly.pem',
                data_enc_method     => $dm,
                key_transport       => $km,
                no_xml_declaration  => 1
            }
        );

        my $encrypted = $encrypter->encrypt($xml);
        ok($encrypted  =~ /EncryptedData/, "Successfully Encrypted: Key Method $km Data Method $dm");

        ok($encrypter->decrypt($encrypted) =~ /XML-SIG_1/, "Successfully Decrypted with XML::Enc");

        SKIP: {
            skip "xmlsec1 not installed", 2 unless which('xmlsec1');
            ok( open XML, '>', 'tmp.xml' );
            print XML $encrypted;
            close XML;
            my $verify_response = `xmlsec1 --decrypt --privkey-pem t/sign-private.pem tmp.xml 2>&1`;
            ok( $verify_response =~ m/XML-SIG_1/, "Successfully decrypted with xmlsec1" )
                or warn "calling xmlsec1 failed: '$verify_response'\n";
            unlink 'tmp.xml';
        }

    }
}
done_testing;
