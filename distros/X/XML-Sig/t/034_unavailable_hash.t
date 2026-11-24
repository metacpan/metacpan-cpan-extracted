use strict;
use warnings;
use Test::More;
use Test::Exception;

# A hash algorithm that the installed Digest::SHA does not provide must be
# reported as unsupported, while the algorithms it does provide keep working.
# Simulate such a Digest::SHA by removing sha224 before XML::Sig is loaded.
BEGIN {
    require Digest::SHA;
    foreach my $name (qw(sha224 hmac_sha224)) {
        delete $Digest::SHA::{$name};
        @Digest::SHA::EXPORT_OK = grep { $_ ne $name } @Digest::SHA::EXPORT_OK;
    }
    ok(!Digest::SHA->can('sha224'), 'sha224 removed from Digest::SHA');
}

use_ok('XML::Sig');

my $CERT = 't/rsa.cert.pem';
my $KEY  = 't/rsa.private.key';
my $XML  = '<Document><Claim ID="legit">some content</Claim></Document>';

my $hmac_key = 'c2VjcmV0IGtleSBmb3IgdGVzdGluZyBvbmx5';

# The algorithms that are available still sign and verify
foreach my $alg (qw(sha1 sha256 sha384 sha512 ripemd160)) {
    my $signed = XML::Sig->new({ key => $KEY, cert => $CERT, digest_hash => $alg })
        ->sign($XML);
    like($signed, qr/DigestMethod Algorithm="[^"]*#$alg"/, "signed with $alg digest");
    ok(XML::Sig->new({ cert => $CERT })->verify($signed), "$alg digest verifies");
}

foreach my $alg (qw(sha1 sha256 sha384 sha512)) {
    my $sig = XML::Sig->new({ hmac_key => $hmac_key, key_name => 'test', sig_hash => $alg });
    ok($sig->verify($sig->sign($XML)), "hmac-$alg signs and verifies");
}

# The algorithm that is not available is rejected when signing ...
throws_ok {
    XML::Sig->new({ key => $KEY, cert => $CERT, digest_hash => 'sha224' })->sign($XML)
} qr/unsupported hash algorithm/, 'signing with an unavailable digest is rejected';

throws_ok {
    XML::Sig->new({ hmac_key => $hmac_key, key_name => 'test', sig_hash => 'sha224' })
        ->sign($XML)
} qr/unsupported hash algorithm/, 'signing with an unavailable hmac is rejected';

# ... and when verifying
my $signed = XML::Sig->new({ key => $KEY, cert => $CERT })->sign($XML);

(my $digest_doc = $signed) =~
    s{(<dsig:DigestMethod Algorithm="[^"#]*#)[^"]*}{${1}sha224};
throws_ok { XML::Sig->new({ cert => $CERT })->verify($digest_doc) }
    qr/unsupported hash algorithm/,
    'verifying a document with an unavailable digest is rejected';

(my $signature_doc = $signed) =~
    s{(<dsig:SignatureMethod Algorithm="[^"#]*#)[^"]*}{${1}rsa-sha224};
throws_ok { XML::Sig->new({ cert => $CERT })->verify($signature_doc) }
    qr/unsupported hash algorithm/,
    'verifying a document with an unavailable signature hash is rejected';

done_testing;
