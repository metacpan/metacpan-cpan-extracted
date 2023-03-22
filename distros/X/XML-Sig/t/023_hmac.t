# -*- perl -*-

use strict;
use warnings;

use Test::Lib;
use Test::XML::Sig;

use Test::More tests => 31;

BEGIN {
    use_ok( 'XML::Sig' );
}

my $key_name = 'tim';
my $hmac_key =<<HMAC;
0xXHREA0s/rJwUIa9diyTJVhHgMs8OgMpp7FvGnUH1TApJeCq+PwZKcVCQQmaNNn
yl5pRE67PP9+f9og/JIg3TdJBbzMR/XVjowRQWY4tM4iufz+TIcgjLtPGgriQ+vk
1ABik1RrS9rZzxgCSvizfUmDaNsS/oIHhyVXoc2JXTM=
HMAC

my $xmlsec  = get_xmlsec_features;
my $openssl = get_openssl_features;

my @hash_alg = qw/sha1 sha224 sha256 sha384 sha512 ripemd160/;
foreach my $alg (@hash_alg) {
    my $xml = '<?xml version="1.0"?>'."\n".'<foo ID="XML-SIG_1">'."\n".'    <bar>123</bar>'."\n".'</foo>';
    my $sig = XML::Sig->new( { hmac_key => $hmac_key, key_name => $key_name, sig_hash => $alg } );
    my $signed = $sig->sign($xml);
    ok( $signed, "Got XML for the response" );

    SKIP: {
        skip "xmlsec1 not installed", 2 unless $xmlsec->{installed};

        # Try whether xmlsec is correctly installed which
        # doesn't seem to be the case on every cpan testing machine

        skip "OpenSSL version 3.0.0 through 3.0.7 do not support ripemd160", 2
            if ( ! $openssl->{ripemd160} and $alg eq 'ripemd160');

        ok( open XML, '>', "tmp-$alg.xml" );
        print XML $signed;
        close XML;
        my $verify_response = `xmlsec1 --verify --keys-file t/xmlsec-keys.xml --id-attr:ID "foo" tmp-$alg.xml 2>&1`;
        ok( $verify_response =~ m/OK/, "Response is OK for xmlsec1" )
            or warn "calling xmlsec1 failed: '$verify_response'\n";
        if ($verify_response =~ m/OK/) {
            unlink "tmp-$alg.xml";
        } else{
            print $signed;
            die;
        }

    }

    my $sig2 = XML::Sig->new( { hmac_key => $hmac_key, key_name => $key_name, sig_hash => $alg } );
    my $result = $sig2->verify($signed);
    ok( $result, "XML Signed Properly" );

    my $sig3 = XML::Sig->new( { hmac_key => 'c2VjcmV0Cg==', key_name => $key_name, sig_hash => $alg } );
    $result = $sig3->verify($signed);
    ok(!$result, "XML Verification failed with incorrect key" );
}
done_testing;
