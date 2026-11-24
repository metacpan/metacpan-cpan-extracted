use strict;
use warnings;
use Test::More;
use Test::Exception;
use MIME::Base64;
use XML::LibXML;
use Crypt::PK::RSA;
use XML::Sig;

# The DigestMethod and SignatureMethod Algorithm names in a document being
# verified are untrusted.  They must only ever select one of the supported
# hash algorithms; they must never be resolved to an arbitrary function by
# name.  Any loaded function can be named with a package qualified name, so
# this test names a harmless function of its own and checks that verify()
# refuses the document without ever calling it.

my $called = 0;
{
    package XML::Sig::Test::Marker;
    sub digest { $called++; return 'x' x 20 }
}
my $MARKER = 'XML::Sig::Test::Marker::digest';

my $CERT = 't/rsa.cert.pem';
my $KEY  = 't/rsa.private.key';
my $DSIG = 'http://www.w3.org/2000/09/xmldsig#';

my $signed = XML::Sig->new({ key => $KEY, cert => $CERT })
    ->sign('<Document><Claim ID="legit">some content</Claim></Document>');

ok(XML::Sig->new({ x509 => 1 })->verify($signed),
    'signed document verifies with the embedded certificate');
ok(XML::Sig->new({ cert => $CERT })->verify($signed),
    'signed document verifies with a provided certificate');

# Change an Algorithm in SignedInfo and re-sign SignedInfo with the private
# key, so the document carries a valid signature over the altered name.
sub resign {
    my ($xml, $change) = @_;

    my $dom = XML::LibXML->load_xml(string => $xml);
    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs('dsig', $DSIG);

    $change->($xpc);

    my ($signed_info) = $xpc->findnodes('//dsig:SignedInfo');
    my ($method) = $xpc->findvalue(
        '//dsig:SignedInfo/dsig:CanonicalizationMethod/@Algorithm');
    die "unexpected canonicalization $method"
        unless $method eq 'http://www.w3.org/2001/10/xml-exc-c14n#';

    my $rsa = Crypt::PK::RSA->new($KEY);
    my $sig = $rsa->sign_message($signed_info->toStringEC14N(), 'SHA256', 'v1.5');

    my ($value) = $xpc->findnodes('//dsig:SignatureValue');
    $value->removeChildNodes;
    $value->appendText(encode_base64($sig, ''));

    return $dom->toString;
}

sub set_algorithm {
    my ($element, $algorithm) = @_;
    return sub {
        my ($xpc) = @_;
        my ($node) = $xpc->findnodes("//dsig:SignedInfo//dsig:$element");
        $node->setAttribute('Algorithm', $algorithm);
    };
}

# The re-signing helper itself produces documents that verify
ok(XML::Sig->new({ x509 => 1 })->verify(resign($signed, sub { })),
    're-signed document verifies');

# DigestMethod naming a function, with a valid signature over SignedInfo
my $digest_doc = resign($signed, set_algorithm('DigestMethod', $DSIG . $MARKER));

throws_ok { XML::Sig->new({ x509 => 1 })->verify($digest_doc) }
    qr/unsupported hash algorithm/,
    'DigestMethod naming a function is rejected (embedded certificate)';
throws_ok { XML::Sig->new({ cert => $CERT })->verify($digest_doc) }
    qr/unsupported hash algorithm/,
    'DigestMethod naming a function is rejected (provided certificate)';
is($called, 0, 'the function named in DigestMethod was not called');

# SignatureMethod naming a function
for my $prefix (qw(rsa- dsa- ecdsa- hmac-), '') {
    (my $doc = $signed) =~
        s{(<dsig:SignatureMethod Algorithm=")[^"]*}{$1$DSIG$prefix$MARKER};
    throws_ok { XML::Sig->new({ x509 => 1 })->verify($doc) }
        qr/unsupported hash algorithm/,
        "SignatureMethod '$prefix' naming a function is rejected";
}
is($called, 0, 'the function named in SignatureMethod was not called');

# Names that are not hash algorithms at all, and a missing algorithm
for my $name ('md5', 'hmac_sha256', '') {
    (my $doc = $signed) =~
        s{(<dsig:DigestMethod Algorithm=")[^"]*}{$1$DSIG$name};
    throws_ok { XML::Sig->new({ x509 => 1 })->verify($doc) }
        qr/unsupported hash algorithm/,
        "DigestMethod '$name' is rejected";
}

# DSA hashes SignedInfo with the SignatureMethod hash before the signature
# is checked, with an embedded key and with a provided certificate alike.
SKIP: {
    skip "Crypt::OpenSSL::DSA >= 0.20 is not installed", 4
        unless XML::Sig->check_dsa_version();

    my $dsa_signed = XML::Sig->new({
        x509 => 1, cert => 't/dsa.public.pem', key => 't/dsa.private.key',
    })->sign('<foo ID="_123"></foo>');
    ok(XML::Sig->new()->verify($dsa_signed), 'DSA signed document verifies');

    (my $doc = $dsa_signed) =~
        s{(<dsig:SignatureMethod Algorithm=")[^"]*}{$1${DSIG}dsa-$MARKER};
    throws_ok { XML::Sig->new()->verify($doc) }
        qr/unsupported hash algorithm/,
        'DSA SignatureMethod naming a function is rejected (embedded certificate)';
    throws_ok { XML::Sig->new({ cert => 't/dsa.public.pem' })->verify($doc) }
        qr/unsupported hash algorithm/,
        'DSA SignatureMethod naming a function is rejected (provided certificate)';
    is($called, 0, 'the function named in the DSA SignatureMethod was not called');
}

done_testing;
