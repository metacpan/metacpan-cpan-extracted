use strict;
use warnings;
use Test::More tests => 126;
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
my @data_methods    = qw/aes128-cbc aes192-cbc aes256-cbc tripledes-cbc aes128-gcm aes192-gcm aes256-gcm/;
my @oaep_mgf_algs   = qw/mgf1sha1 mgf1sha224 mgf1sha256 mgf1sha384 mgf1sha512/;

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
            my $version;
            if (`xmlsec1 version` =~ m/(\d+\.\d+\.\d+)/) {
                $version = $1;
            };
            skip "xmlsec version 1.2.27 minimum for GCM", 2 if $version lt '1.2.27';
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

foreach my $om (@oaep_mgf_algs) {
    foreach my $dm (@data_methods) {
        my $encrypter = XML::Enc->new(
            {
                key                 => 't/sign-private.pem',
                cert                => 't/sign-certonly.pem',
                data_enc_method     => $dm,
                key_transport       => 'rsa-oaep',
                oaep_mgf_alg        => $om,
                no_xml_declaration  => 1
            }
        );

        my $encrypted = $encrypter->encrypt($xml);
        ok($encrypted  =~ /EncryptedData/, "Successfully Encrypted: Key Method 'rsa-oaep' with $om Data Method $dm");

        ok($encrypter->decrypt($encrypted) =~ /XML-SIG_1/, "Successfully Decrypted with XML::Enc");
    }
}
done_testing;
