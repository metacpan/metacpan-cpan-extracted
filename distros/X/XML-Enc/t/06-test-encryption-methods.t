use strict;
use warnings;
use Test::More tests => 896;
use Test::Lib;
use Test::XML::Enc;
use XML::Enc;
use MIME::Base64 qw/decode_base64 encode_base64/;

my $xml = <<'XML';
<?xml version="1.0"?>
<foo ID="XML-SIG_1">
    <bar>123</bar>
</foo>
XML

my $key_name        = 'mykey';
my @key_methods     = qw/rsa-1_5 rsa-oaep-mgf1p/;
my @data_methods    = qw/aes128-cbc aes192-cbc aes256-cbc tripledes-cbc aes128-gcm aes192-gcm aes256-gcm/;
my @oaep_mgf_algs   = qw/rsa-oaep-mgf1p mgf1sha1 mgf1sha224 mgf1sha256 mgf1sha384 mgf1sha512/;
my @oaep_label_hashes    = qw/sha1 sha224 sha256 sha384 sha512/;

my $xmlsec = get_xmlsec_features();
my $lax_key_search = $xmlsec->{lax_key_search} ? '--lax-key-search': '';
my $cryptx = get_cryptx_features();

foreach my $km (@key_methods) {
    foreach my $dm (@data_methods) {
        my $encrypter = XML::Enc->new(
            {
                key                 => 't/sign-private.pem',
                cert                => 't/sign-certonly.pem',
                key_name            => $key_name,
                data_enc_method     => $dm,
                key_transport       => $km,
                no_xml_declaration  => 1
            }
        );

        my $encrypted = $encrypter->encrypt($xml);
        like($encrypted, qr/EncryptedData/, "Successfully Encrypted: Key Method $km Data Method $dm");

        like($encrypter->decrypt($encrypted), qr/XML-SIG_1/, "Successfully Decrypted with XML::Enc");

        SKIP: {
            skip "xmlsec1 not installed", 2 unless $xmlsec->{installed};
            skip "xmlsec version 1.2.27 minimum for GCM", 2 if ! $xmlsec->{aes_gcm};
            ok( open XML, '>', "enc-xml-$km-$dm.xml" );
            print XML $encrypted;
            close XML;
            my $verify_response = `xmlsec1 --decrypt $lax_key_search --privkey-pem:$key_name t/sign-private.pem,t/sign-certonly.pem enc-xml-$km-$dm.xml 2>&1`;
            like($verify_response, qr/XML-SIG_1/, "Successfully decrypted with xmlsec1" )
                or warn "calling xmlsec1 failed: '$verify_response'\n";
            unlink "enc-xml-$km-$dm.xml";
        }
    }
}
foreach my $om (@oaep_mgf_algs) {
    foreach my $omdig (@oaep_label_hashes) {
        SKIP: {
            if (! $cryptx->{oaem_mgf_digest} && ($om ne $omdig)) {
                my $skip = (scalar @data_methods) * 4;
                skip "CryptX $cryptx->{version} does not support rsa-oaep MGF: $om and digest $omdig", $skip;
            }

            my $km = ( $om eq 'rsa-oaep-mgf1p') ? 'rsa-oaep-mgf1p' : 'rsa-oaep';
            foreach my $dm (@data_methods) {
                my $encrypter = XML::Enc->new(
                    {
                        key                 => 't/sign-private.pem',
                        cert                => 't/sign-certonly.pem',
                        key_name            => $key_name,
                        data_enc_method     => $dm,
                        key_transport       => $km,
                        oaep_mgf_alg        => $om,
                        oaep_label_hash     => $omdig,
                        oaep_params         => 'encrypt',
                        no_xml_declaration  => 1,
                    }
                );

                my $encrypted = $encrypter->encrypt($xml);
                ok($encrypted  =~ /EncryptedData/, "Successful Encrypted: Key Method:$km MGF:$om, param:$omdig Data Method:$dm");

                SKIP: {
                    skip "xmlsec1 not installed", 2 unless $xmlsec->{installed};
                    skip "xmlsec version 1.2.27 minimum for GCM", 2 if ! $xmlsec->{aes_gcm};
                    skip "xmlsec version 1.3.00 minimum for rsa-oeap", 2 if ! $xmlsec->{rsa_oaep};
                    ok( open XML, '>', "enc-xml-$km-$om-$omdig-$dm.xml" );
                    print XML $encrypted;
                    close XML;
                    my $verify_response = `xmlsec1 --decrypt $lax_key_search --privkey-pem:$key_name t/sign-private.pem,t/sign-certonly.pem enc-xml-$km-$om-$omdig-$dm.xml 2>&1`;
                    ok( $verify_response =~ m/XML-SIG_1/, "Successfully decrypted with xmlsec1" )
                        or warn "calling xmlsec1 failed: '$verify_response'\n";
                    unlink "enc-xml-$km-$om-$omdig-$dm.xml";
                }
                ok($encrypter->decrypt($encrypted) =~ /XML-SIG_1/, "Successfully Decrypted with XML::Enc");
            }
        }
    }
}
done_testing;
