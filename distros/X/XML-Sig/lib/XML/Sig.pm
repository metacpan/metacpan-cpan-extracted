package XML::Sig;

# use 'our' on v5.6.0
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS $DEBUG);

$DEBUG = 0;
$VERSION = '0.22';

use base qw(Class::Accessor);
XML::Sig->mk_accessors(qw(canonicalizer key));

# We are exporting functions
use base qw/Exporter/;

# Export list - to allow fine tuning of export table
@EXPORT_OK = qw( sign verify );

use strict;

use Digest::SHA1 qw(sha1 sha1_base64);
use XML::XPath;
use MIME::Base64;
use Carp;

use constant TRANSFORM_ENV_SIG           => 'http://www.w3.org/2000/09/xmldsig#enveloped-signature';
use constant TRANSFORM_EXC_C14N          => 'http://www.w3.org/2001/10/xml-exc-c14n#';
use constant TRANSFORM_EXC_C14N_COMMENTS => 'http://www.w3.org/2001/10/xml-exc-c14n#WithComments';

sub DESTROY { }

$SIG{INT} = sub { die "Interrupted\n"; };

$| = 1;  # autoflush

sub new {
    my $class = shift;
    my $params = shift;
    my $self = {};
    foreach my $prop ( qw/ key / ) {
        if ( exists $params->{ $prop } ) {
            $self->{ $prop } = $params->{ $prop };
        }
#        else {
#            confess "You need to provide the $prop parameter!";
#        }
    }
    bless $self, $class;
    $self->{ 'canonicalizer' } =
	exists $params->{ canonicalizer } ? $params->{ canonicalizer } : 'XML::CanonicalizeXML';
    $self->{ 'x509' } = exists $params->{ x509 } ? 1 : 0;
    if ( exists $params->{ 'key' } ) {
	$self->_load_key( $params->{ 'key' } );
    }
    return $self;
}

sub sign {
    my $self = shift;
    my ($xml) = @_;

    die "You cannot sign XML without a private key." unless $self->key;

    $self->{ parser } = XML::XPath->new( xml => $xml );

    $xml = $self->_get_xml_to_sign();

    # We now calculate the SHA1 digest of the canoncial response xml
    my $canonical     = $self->_canonicalize_xml( $xml );

    my $bin_digest    = sha1( $canonical );
    my $digest        = encode_base64( $bin_digest, '' );

    # Create a xml fragment containing the digest:
    my $digest_xml    = $self->_reference_xml( $digest );

    # create a xml fragment consisting of the SignedInfo element
    my $signed_info   = $self->_signedinfo_xml( $digest_xml );

    # We now calculate a signature over the canonical SignedInfo element

    $canonical        = $self->_canonicalize_xml( $signed_info );

    my $signature;
    if ($self->{key_type} eq 'dsa') {
	# DSA only permits the signing of 20 bytes or less, hence the sha1
	my $bin_signature  = $self->{key_obj}->sign( sha1($canonical) );
	$signature     = encode_base64( $bin_signature, "\n" );
    } else {
	my $bin_signature = $self->{key_obj}->sign( $canonical );
	$signature     = encode_base64( $bin_signature, "\n" );
    }

    # With the signature value and the signedinfo element, we create
    # a Signature element:
    my $signature_xml = $self->_signature_xml( $signed_info, $signature );

    # Now insert the signature xml into our response xml
    $xml =~ s/(<\/[^>]*>)$/$signature_xml$1/;

    return $xml;
}

sub verify {
    my $self = shift;
    my ($xml) = @_;
    
    $self->{ parser } = XML::XPath->new( xml => $xml );

    my $signature                = _trim($self->{parser}->findvalue('//Signature/SignatureValue'));
    my $signed_info              = $self->_get_node_as_text('//Signature/SignedInfo');
    my $signed_info_canon        = $self->_canonicalize_xml( $signed_info );

    my $keyinfo_node;
    if ($keyinfo_node = $self->{parser}->find('//Signature/KeyInfo/X509Data')) {
	return 0 unless $self->_verify_x509($keyinfo_node,$signed_info_canon,$signature);
    } 
    elsif ($keyinfo_node = $self->{parser}->find('//Signature/KeyInfo/KeyValue/RSAKeyValue')) {
	return 0 unless $self->_verify_rsa($keyinfo_node,$signed_info_canon,$signature);
    }
    elsif ($keyinfo_node = $self->{parser}->find('//Signature/KeyInfo/KeyValue/DSAKeyValue')) {
	return 0 unless $self->_verify_dsa($keyinfo_node,$signed_info_canon,$signature);
    }
    else {
	die "Unrecognized key type in signature.";
    }

    my $digest_method = $self->{parser}->findvalue('//Signature/SignedInfo/Reference/DigestMethod/@Algorithm');
    my $digest = _trim($self->{parser}->findvalue('//Signature/SignedInfo/Reference/DigestValue'));
    
    my $signed_xml    = $self->_get_signed_xml();
    my $canonical     = $self->_transform( $signed_xml );
    my $digest_bin    = sha1( $canonical ); 

    return 1 if ($digest eq _trim(encode_base64($digest_bin)));
    return 0;
}

sub _get_xml_to_sign {
    my $self = shift;
    my $id = $self->{parser}->findvalue('//@ID');
    die "You cannot sign an XML document without identifying the element to sign with an ID attribute" unless $id;
    $self->{'sign_id'} = $id;
    my $xpath = "//*[\@ID='$id']";
    return $self->_get_node_as_text( $xpath );
}

sub _get_signed_xml {
    my $self = shift;
    my $id = $self->{parser}->findvalue('//Signature/SignedInfo/Reference/@URI');
    $id =~ s/^#//;
    $self->{'sign_id'} = $id;
    my $xpath = "//*[\@ID='$id']";
    return $self->_get_node_as_text( $xpath );
}

sub _transform {
    my $self = shift;
    my ($xml) = @_;
    foreach my $node ($self->{parser}->find('//Transform/@Algorithm')->get_nodelist) {
	my $alg = $node->getNodeValue;
	if ($alg eq TRANSFORM_ENV_SIG) { $xml = $self->_transform_env_sig($xml); }
	elsif ($alg eq TRANSFORM_EXC_C14N) { $xml = $self->_canonicalize($xml,0); }
	elsif ($alg eq TRANSFORM_EXC_C14N_COMMENTS) { $xml = $self->canonicalize($xml,1); }
	else { die "Unsupported transform: $alg"; }
    }
    return $xml;
}

sub _verify_rsa {
    my $self = shift;
    my ($context,$canonical,$sig) = @_;

    # Generate Public Key from XML
    my $mod = _trim($self->{parser}->findvalue('//Signature/KeyInfo/KeyValue/RSAKeyValue/Modulus'));
    my $modBin = decode_base64( $mod );
    my $exp = _trim($self->{parser}->findvalue('//Signature/KeyInfo/KeyValue/RSAKeyValue/Exponent'));
    my $expBin = decode_base64( $exp );
    my $n = Crypt::OpenSSL::Bignum->new_from_bin($modBin);
    my $e = Crypt::OpenSSL::Bignum->new_from_bin($expBin);
    my $rsa_pub = Crypt::OpenSSL::RSA->new_key_from_parameters( $n, $e );

    # Decode signature and verify
    my $bin_signature = decode_base64($sig);
    return 1 if ($rsa_pub->verify( $canonical,  $bin_signature ));
    return 0;
}

sub _clean_x509 {
    my $self = shift;
    my ($cert) = @_;
    $cert =~ s/\n//g;
#    my $n = 64;    # $n is group size.
#    my @parts = unpack "a$n" x ((length($cert)/$n)-0) . "a*", $cert;
#    $cert = join("\n",@parts);
    $cert = "-----BEGIN PUBLIC KEY-----\n" . $cert . "\n-----END PUBLIC KEY-----\n";
    return $cert;
}

sub _verify_x509 {
    my $self = shift;
    my ($context,$canonical,$sig) = @_;

    eval {
	require Crypt::OpenSSL::X509;
        require Crypt::OpenSSL::RSA;
    };

    # Generate Public Key from XML
    my $certificate = _trim($self->{parser}->findvalue('//Signature/KeyInfo/X509Data/X509Certificate'));
    # This is added because the X509 parser requires it for self-identification
    $certificate = $self->_clean_x509($certificate);

    my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($certificate);

    # Decode signature and verify
    my $bin_signature = decode_base64($sig);

    return 1 if ($rsa_pub->verify( $canonical,  $bin_signature ));
    return 0;
}


sub _verify_dsa {
    my $self = shift;
    my ($context,$canonical,$sig) = @_;

    eval {
        require Crypt::OpenSSL::DSA;
    };

    # Generate Public Key from XML
    my $p = decode_base64(_trim($self->{parser}->findvalue('//Signature/KeyInfo/KeyValue/DSAKeyValue/P')));
    my $q = decode_base64(_trim($self->{parser}->findvalue('//Signature/KeyInfo/KeyValue/DSAKeyValue/Q')));
    my $g = decode_base64(_trim($self->{parser}->findvalue('//Signature/KeyInfo/KeyValue/DSAKeyValue/G')));
    my $y = decode_base64(_trim($self->{parser}->findvalue('//Signature/KeyInfo/KeyValue/DSAKeyValue/Y')));
    my $dsa_pub = Crypt::OpenSSL::DSA->new();
    $dsa_pub->set_p($p);
    $dsa_pub->set_q($q);
    $dsa_pub->set_g($g);
    $dsa_pub->set_pub_key($y);

    # Decode signature and verify
    my $bin_signature = decode_base64($sig);
    # DSA signatures are limited to a message body of 20 characters, so a sha1 digest is taken
    return 1 if ($dsa_pub->verify( sha1($canonical),  $bin_signature ));
    return 0;
}

sub _get_node {
    my $self = shift;
    my ($xpath) = @_;
    my $nodeset = $self->{parser}->find($xpath);
    foreach my $node ($nodeset->get_nodelist) {
        return $node; 
    }
}

sub _get_node_as_text {
    my $self = shift;
    return XML::XPath::XMLParser::as_string( $self->_get_node(@_) );
}

sub _transform_env_sig {
    my $self = shift;
    my ($str) = @_;
    $str =~ s/(<Signature(.*?)>(.*?)\<\/Signature>)//igs;
    return $str;
}

sub _trim {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub _load_dsa_key {
    my $self = shift;
    my $key_text = shift;

    eval {
        require Crypt::OpenSSL::DSA;
    };

    confess "Crypt::OpenSSL::DSA needs to be installed so that we can handle DSA keys." if $@;

    my $dsa_key = Crypt::OpenSSL::DSA->read_priv_key_str( $key_text );

    if ( $dsa_key ) {
        $self->{ key_obj } = $dsa_key;
        my $g = encode_base64( $dsa_key->get_g(), '' );
        my $p = encode_base64( $dsa_key->get_p(), '' );
        my $q = encode_base64( $dsa_key->get_q(), '' );
        my $y = encode_base64( $dsa_key->get_pub_key(), '' );

        $self->{KeyInfo} = "<KeyInfo><KeyValue><DSAKeyValue><P>$p</P><Q>$q</Q><G>$g</G><Y>$y</Y></DSAKeyValue></KeyValue></KeyInfo>";
        $self->{key_type} = 'dsa';
    }
    else {
        confess "did not get a new Crypt::OpenSSL::RSA object";
    }
}


sub _load_rsa_key {
    my $self = shift;
    my ($key_text) = @_;

    eval {
        require Crypt::OpenSSL::RSA;
    };

    my $rsaKey = Crypt::OpenSSL::RSA->new_private_key( $key_text );

    if ( $rsaKey ) {
        $rsaKey->use_pkcs1_padding();
        $self->{ key_obj }  = $rsaKey;
        $self->{ key_type } = 'rsa';

	if ($self->{'x509'}) {
	    my $cert = $rsaKey->get_public_key_x509_string();
	    $cert =~ s/-----[^-]*-----//gm;
	    $self->{KeyInfo} = "<KeyInfo><X509Data><X509Certificate>\n"._trim($cert)."\n</X509Certificate></X509Data></KeyInfo>";
	} else {
	    my $bigNum = ( $rsaKey->get_key_parameters() )[1];
	    my $bin = $bigNum->to_bin();
	    my $exp = encode_base64( $bin, '' );
	    
	    $bigNum = ( $rsaKey->get_key_parameters() )[0];
	    $bin = $bigNum->to_bin();
	    my $mod = encode_base64( $bin, '' );
	    $self->{KeyInfo} = "<KeyInfo><KeyValue><RSAKeyValue><Modulus>$mod</Modulus><Exponent>$exp</Exponent></RSAKeyValue></KeyValue></KeyInfo>";
	}
    }
    else {
        confess "did not get a new Crypt::OpenSSL::RSA object";
    }
}

sub _load_x509_key {
    my $self = shift;
    my $key_text = shift;

    eval {
        require Crypt::OpenSSL::X509;
    };

    my $x509Key = Crypt::OpenSSL::X509->new_private_key( $key_text );

    if ( $x509Key ) {
        $x509Key->use_pkcs1_padding();
        $self->{ key_obj } = $x509Key;
        my $cert = $x509Key->pubkey;
	$cert =~ s/^-----[^-]*-----\n$//gm;
        $self->{KeyInfo} = "<KeyInfo><X509Data><X509Certificate>\n$cert\n</X509Certificate></X509Data></KeyInfo>";
        $self->{key_type} = 'x509';
    }
    else {
        confess "did not get a new Crypt::OpenSSL::X509 object";
    }
}

sub _set_key_info {
    my $self = shift;

}

sub _load_key {
    my $self = shift;
    my $file = $self->{ key };

    if ( open my $KEY, '<', $file ) {
        my $text = '';
        local $/ = undef;
        $text = <$KEY>;
        close $KEY;

        if ( $text =~ m/BEGIN ([DR]SA) PRIVATE KEY/ ) {
            my $key_used = $1;

            if ( $key_used eq 'RSA' ) {
                $self->_load_rsa_key( $text );
            }
            else {
                $self->_load_dsa_key( $text );
            }

            return 1;
	} elsif ( $text =~ m/BEGIN PRIVATE KEY/ ) {
	    $self->_load_rsa_key( $text );
        } elsif ($text =~ m/BEGIN CERTIFICATE/) {
	    $self->_load_x509_key( $text );
	}
        else {
            confess "Could not detect type of key $file.";
        }
    }
    else {
        confess "Could not load key $file: $!";
    }

    return;
}

sub _signature_xml {
    my $self = shift;
    my ($signed_info,$signature_value) = @_;
    return qq{<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
            $signed_info
            <SignatureValue>$signature_value</SignatureValue>
            $self->{KeyInfo}
        </Signature>};
}

sub _signedinfo_xml {
    my $self = shift;
    my ($digest_xml) = @_;

    return qq{<SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#">
                <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments" />
                <SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#$self->{key_type}-sha1" />
                $digest_xml
            </SignedInfo>};
}

sub _reference_xml {
    my $self = shift;
    my ($digest) = @_;
    my $id = $self->{sign_id};
    return qq{<Reference URI="#$id">
                        <Transforms>
                            <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />
                        </Transforms>
                        <DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />
                        <DigestValue>$digest</DigestValue>
                    </Reference>};
}

sub _canonicalize_xml {
    my $self = shift;
    my ($xml,$comments) = @_;
    $comments = 0 unless $comments;

    if ( $self->{canonicalizer} eq 'XML::Canonical' ) {
        require XML::Canonical;
        my $xmlcanon = XML::Canonical->new( comments => $comments );
        return $xmlcanon->canonicalize_string( $xml );
    }
    elsif ( $self->{ canonicalizer } eq 'XML::CanonicalizeXML' ) {
        require XML::CanonicalizeXML;
        my $xpath = '<XPath>(//. | //@* | //namespace::*)</XPath>';
	return XML::CanonicalizeXML::canonicalize( $xml, $xpath, [], 0, $comments );
    }
    else {
        confess "Unknown XML canonicalizer module.";
    }
}

1;
__END__

=head1 NAME

XML::Sig - A toolkit to help sign and verify XML Digital Signatures.

=head1 DESCRIPTION

This perl module provides two primary capabilities: given an XML string, create
and insert a digital signature, or if one is already present in the string verify 
it -- all in accordance with the W3C standard governing XML signatures.

=head1 ABOUT DIGITAL SIGNATURES

Just as one might want to send an email message that is cryptographically signed
in order to give the recipient the means to independently verify who sent the email,
one might also want to sign an XML document. This is especially true in the 
scenario where an XML document is received in an otherwise unauthenticated 
context, e.g. SAML.

However XML provides a challenge that email does not. In XML, two documents can be 
byte-wise inequivalent, and semanticaly equivalent at the same time. For example:

    <?xml version="1.0"?>
    <foo>
      <bar />
    </foo>

    And:

    <?xml version="1.0"?>
    <foo>
      <bar></bar>
    </foo>

Each of these document express the same thing, or in other words they "mean"
the same thing. However if you were to strictly sign the raw text of these 
documents, they would each produce different signatures. 

XML Signatures on the other hand will produce the same signature for each of 
the documents above. Therefore an XML document can be written and rewritten by 
different parties and still be able to have someone at the end of the line 
verify a signature the document may contain.

There is a specially subscribed methodology for how this process should be
executed and involves transforming the XML into its canonical form so a 
signature can be reliably inserted or extracted for verification. This
module implements that process.

=head2 EXAMPLE SIGNATURE

Below is a sample XML signature to give you some sense of what they look like.
First let's look at the original XML document, prior to being signed:

  <?xml version="1.0"?>
  <foo ID="abc">
    <bar>123</bar>
  </foo>

Now, let's insert a signature:

  <?xml version="1.0"?>
  <foo ID="abc">
    <bar>123</bar>
    <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
      <SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#" xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:xenc="http://www.w3.org/2001/04/xmlenc#">
        <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments" />
        <SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />
        <Reference URI="#abc">
          <Transforms>
            <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />
          </Transforms>
          <DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />
          <DigestValue>9kpmrvv3peVJpNSTRycrV+jeHVY=</DigestValue>
        </Reference>
      </SignedInfo>
      <SignatureValue>
        HXUBnMgPJf//j4ihaWnaylNwAR5AzDFY83HljFIlLmTqX1w1C72ZTuRObvYve8TNEbVsQlTQkj4R
        hiY0pgIMQUb75GLYFtc+f0YmBZf5rCWY3NWzo432D3ogAvpEzYXEQPmicWe2QozQhybaz9/wrYki
        XiXY+57fqCkf7aT8Bb6G+fn7Aj8gnZFLkmKxwCdyGsIZOIZdQ8MWpeQrifxBR0d8W1Zm6ix21WNv
        ONt575h7VxLKw8BDhNPS0p8CS3hOnSk29stpiDMCHFPxAwrbKVL1kGDLaLZn1q8nNRmH8oFxG15l
        UmS3JXDZAss8gZhU7g9T4XllCqjrAvzPLOFdeQ==
      </SignatureValue>
      <KeyInfo>
        <KeyValue>
          <RSAKeyValue>
            <Modulus>
              1b+m37u3Xyawh2ArV8txLei251p03CXbkVuWaJu9C8eHy1pu87bcthi+T5WdlCPKD7KGtkKn9vq
              i4BJBZcG/Y10e8KWVlXDLg9gibN5hb0Agae3i1cCJTqqnQ0Ka8w1XABtbxTimS1B0aO1zYW6d+U
              Yl0xIeAOPsGMfWeu1NgLChZQton1/NrJsKwzMaQy1VI8m4gUleit9Z8mbz9bNMshdgYEZ9oC4bH
              n/SnA4FvQl1fjWyTpzL/aWF/bEzS6Qd8IBk7yhcWRJAGdXTWtwiX4mXb4h/2sdrSNvyOsd/shCf
              OSMsf0TX+OdlbH079AsxOwoUjlzjuKdCiFPdU6yAJw==
            </Modulus>
            <Exponent>Iw==</Exponent>
          </RSAKeyValue>
        </KeyValue>
      </KeyInfo>
    </Signature>
  </foo>

=head1 PREREQUISITES

=over

=item L<Digest::SHA1>

=item L<XML::XPath>

=item L<MIME::Base64>

=item L<Crypt::OpenSSL::X509>

=item L<Crypt::OpenSSL::RSA>

=cut

=head1 USAGE

=head2 SUPPORTED ALGORITHMS & TRANSFORMS

This module supports the following signature methods:

=over 

=item DSA

=item RSA

=item RSA encoded as x509

=cut

This module supports the following canonicalization methods and transforms:

=over 

=item EXC-X14N#

=item EXC-X14#WithComments

=item Enveloped Signature

=cut

=head2 METHODS

=over

=item B<sign($xml)>

When given a string of XML, it will return the same string with a signature
generated from the key provided when the XML::Sig object was initialized. 

This method presumes that there is one and only one element in your XML
document with an ID (case sensitive) attribute. This is the element that will
be the basis for the signature. It will also correspond to the URI attribute
in the Reference element that will be contained by the signature. If no ID
attribute can be found on an element, the signature will not be created.

=item B<verify($xml)>

Returns true or false based upon whether the signature is valid or not. 

When using XML::Sig exclusively to verify a signature, no key needs to be
specified during initialization given that the public key should be
transmitted with the signature.

=cut

=head2 OPTIONS

Each of the following options are also accessors on the main
File::Download object.

=over

=item B<key>

The path to a file containing the contents of a private key. This option
is used only when generating signatures.

=item B<canonicalizer>

The XML canonicalization library to use. Options currently are:

=over

=item XML::CanonicalizerXML (default)

=item XML::Canonicalizer

=cut

=item B<x509>

Takes a true (1) or false (0) value and indicates how you want the 
signature to be encoded. When true, an X509 certificate will be 
encoded in the signature. Otherwise the native encoding format for
RSA and DSA will be used.

=cut

=head1 EXAMPLE

Fetch the newest and greatest perl version:

   my $xml = '<foo ID="abc">123</foo>';
   my $signer = XML::Sig->new({
     canonicalizer => 'XML-CanonizeXML',
     key => 'path/to/private.key',
   });
   my $signed = $signer->sign($xml);
   print "Signed XML: $signed\n";
   $signer->verify($signed) 
     or die "Signature Invalid.";
   print "Signature valid.\n";

=head1 SEE ALSO

L<http://www.w3.org/TR/xmldsig-core/>

=head1 AUTHORS and CREDITS

Author: Byrne Reese <byrne@majordojo.com>

Thanks to Manni Heumann who wrote Google::SAML::Response from 
which this module borrows heavily in order to create digital 
signatures.

=cut
