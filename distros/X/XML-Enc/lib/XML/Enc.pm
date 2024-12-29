use strict;
use warnings;

package XML::Enc;
our $VERSION = '0.15'; # VERSION

# ABSTRACT: XML::Enc Encryption Support

use Carp;
use Crypt::AuthEnc::GCM 0.062;
use Crypt::Mode::CBC;
use Crypt::PK::RSA 0.081;
use Crypt::PRNG qw( random_bytes );
use MIME::Base64 qw/decode_base64 encode_base64/;
use XML::LibXML;

# state means perl 5.10
use feature 'state';
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS $DEBUG);

our $DEBUG = 0;


# Source: https://www.w3.org/TR/2002/REC-xmlenc-core-20021210/Overview.html#sec-Alg-Block
# 5.2.1 Triple DES - 64 bit Initialization Vector (IV) (8 bytes)
# 5.2.2 AES - 128 bit initialization vector (IV) (16 bytes)

sub _assert_symmetric_algorithm {
    my $algo = shift;

    state $SYMMETRIC = {
        'http://www.w3.org/2001/04/xmlenc#tripledes-cbc' => {
            ivsize   => 8,
            keysize  => 24,
            modename => 'DES_EDE'
        },
        'http://www.w3.org/2001/04/xmlenc#aes128-cbc' => {
            ivsize   => '16',
            keysize  => 16,
            modename => 'AES'
        },
        'http://www.w3.org/2001/04/xmlenc#aes192-cbc' => {
            ivsize   => '16',
            keysize  => 24,
            modename => 'AES'
        },
        'http://www.w3.org/2001/04/xmlenc#aes256-cbc' => {
            ivsize   => '16',
            keysize  => 32,
            modename => 'AES'
        },
        'http://www.w3.org/2009/xmlenc11#aes128-gcm' => {
            ivsize   => '12',
            keysize  => 16,
            modename => 'AES',
            tagsize  => 16
        },
        'http://www.w3.org/2009/xmlenc11#aes192-gcm' => {
            ivsize   => '12',
            keysize  => 24,
            modename => 'AES',
            tagsize  => 16
        },
        'http://www.w3.org/2009/xmlenc11#aes256-gcm' => {
            ivsize   => '12',
            keysize  => 32,
            modename => 'AES',
            tagsize  => 16
        },
    };

    die "Unsupported symmetric algo $algo" unless $SYMMETRIC->{ $algo };
    return $SYMMETRIC->{$algo}
}

sub _assert_encryption_digest {
    my $algo = shift;

    state $ENC_DIGEST = {
        'http://www.w3.org/2000/09/xmldsig#sha1' => 'SHA1',
        'http://www.w3.org/2001/04/xmlenc#sha256' => 'SHA256',
        'http://www.w3.org/2001/04/xmldsig-more#sha224' => 'SHA224',
        'http://www.w3.org/2001/04/xmldsig-more#sha384' => 'SHA384',
        'http://www.w3.org/2001/04/xmlenc#sha512' => 'SHA512',
    };
    die "Unsupported encryption digest algo $algo" unless $ENC_DIGEST->{ $algo };
    return $ENC_DIGEST->{ $algo };
}



sub new {
    my $class   = shift;
    my $params  = shift;
    my $self    = {};

    bless $self, $class;

    if ( exists $params->{ 'key' } ) {
        $self->{key} = $params->{ 'key' };
        $self->_load_key( $params->{ 'key' } );
    }
    if ( exists $params->{ 'cert' } ) {
        $self->{cert} = $params->{ 'cert' };
        $self->_load_cert_file( $params->{ 'cert' } );
    }
    if (exists $params->{'no_xml_declaration'}) {
        $self->{'no_xml_declaration'} = $params->{'no_xml_declaration'} ? $params->{'no_xml_declaration'} : 0;
    }

    my $enc_method = exists($params->{'data_enc_method'}) ? $params->{'data_enc_method'} : 'aes256-cbc';
    $self->{'data_enc_method'} = $self->_setEncryptionMethod($enc_method);

    my $key_method = exists($params->{'key_transport'}) ? $params->{'key_transport'} : 'rsa-oaep-mgf1p ';
    $self->{'key_transport'} = $self->_setKeyEncryptionMethod($key_method);

    if (exists $params->{'oaep_mgf_alg'}) {
        $self->{'oaep_mgf_alg'} = $self->_setOAEPAlgorithm($params->{'oaep_mgf_alg'});
    }
    if (exists $params->{'oaep_label_hash'} ) {
        $self->{'oaep_label_hash'} = $self->_setOAEPDigest($params->{'oaep_label_hash'});
    }

    $self->{'oaep_params'} = exists($params->{'oaep_params'}) ? $params->{'oaep_params'} : '';

    $self->{'key_name'} = $params->{'key_name'} if exists($params->{'key_name'});

    return $self;
}


sub decrypt {
    my $self = shift;
    my $xml  = shift;
    my %options = @_;

    local $XML::LibXML::skipXMLDeclaration = $self->{ no_xml_declaration };

    my $doc = XML::LibXML->load_xml( string => $xml );

    my $xpc = XML::LibXML::XPathContext->new($doc);
    $xpc->registerNs('dsig', 'http://www.w3.org/2000/09/xmldsig#');
    $xpc->registerNs('xenc', 'http://www.w3.org/2001/04/xmlenc#');
    $xpc->registerNs('xenc11', 'http://www.w3.org/2009/xmlenc11#');
    $xpc->registerNs('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');

    return $doc unless $xpc->exists('//xenc:EncryptedData');

    die "You cannot decrypt XML without a private key." unless $self->{key_obj};

    my $parser = XML::LibXML->new();
    $self->_decrypt_encrypted_key_nodes($xpc, $parser, %options);
    $self->_decrypt_uri_nodes($xpc, $parser, %options);

    return $doc->serialize();
}

sub _decrypt_encrypted_key_nodes {
    my $self = shift;
    my $xpc = shift;
    my $parser = shift;
    my %options = @_;

    my $k = $self->_get_named_key_nodes(
        '//xenc:EncryptedData/dsig:KeyInfo/xenc:EncryptedKey',
        $xpc, $options{key_name}
    );

    $k->foreach(
        sub {
            my $key = $self->_get_key_from_node($_, $xpc);
            return unless $key;
            my $encrypted_node = $_->parentNode->parentNode;
            $self->_decrypt_encrypted_node($encrypted_node,
                $key, $xpc, $parser);
        }
    );
}

sub _decrypt_uri_nodes {
    my $self = shift;
    my $xpc  = shift;
    my $parser = shift;
    my %options = @_;

    my $uri_nodes = $xpc->findnodes('//dsig:KeyInfo/dsig:RetrievalMethod/@URI');
    my @uri_nodes = $uri_nodes->map(sub { my $v = $_->getValue; $v =~ s/^#//; return $v; });

    foreach my $uri (@uri_nodes) {
        my $encrypted_key_nodes = $self->_get_named_key_nodes(
            sprintf('//xenc:EncryptedKey[@Id="%s"]', $uri),
            $xpc, $options{key_name});

        $encrypted_key_nodes->foreach(
            sub {

                my $key = $self->_get_key_from_node($_, $xpc);
                return unless $key;

                my $encrypted_nodes = $xpc->findnodes(sprintf('//dsig:KeyInfo/dsig:RetrievalMethod[@URI="#%s"]/../..', $uri));
                return unless $encrypted_nodes->size;

                $encrypted_nodes->foreach(sub {
                    $self->_decrypt_encrypted_node(
                        $_,
                        $key,
                        $xpc,
                        $parser
                    );
                });

                # We don't need the encrypted key here
                $_->removeChildNodes();
            }
        );
    }
}

sub _get_named_key_nodes {
    my $self = shift;
    my $xpath = shift;
    my $xpc = shift;
    my $name = shift;

    my $nodes = $xpc->findnodes($xpath);
    return $nodes unless $name;
    return $nodes->grep(
        sub {
            $xpc->findvalue('dsig:KeyInfo/dsig:KeyName', $_) eq $name;
        }
    );
}

sub _decrypt_encrypted_node {
    my $self = shift;
    my $node = shift;
    my $key  = shift;
    my $xpc  = shift;
    my $parser = shift;

    my $algo         = $self->_get_encryption_algorithm($node, $xpc);
    my $cipher_value = $self->_get_cipher_value($node, $xpc);
    my $oaep         = $self->_get_oaep_params($node, $xpc);

    my $decrypted_data = $self->_DecryptData($algo, $key, $cipher_value);

    # Sooo.. parse_balanced_chunk breaks when there is a <xml version="1'>
    # bit in the decrypted data and thus we have to remove it.
    # We try parsing the XML here and if that works we get all the nodes
    my $new = eval { $parser->load_xml(string => $decrypted_data)->findnodes('//*')->[0]; };

    if ($new) {
        $node->addSibling($new);
        $node->unbindNode();
        return;
    }

    $decrypted_data = $parser->parse_balanced_chunk($decrypted_data);
    if (($node->parentNode->localname //'') eq 'EncryptedID') {
        $node->parentNode->replaceNode($decrypted_data);
        return;
    }
    $node->replaceNode($decrypted_data);
    return;
}

sub _get_key_from_node {
    my $self = shift;
    my $node = shift;
    my $xpc  = shift;

    my $algo         = $self->_get_encryption_algorithm($_, $xpc);
    my $cipher_value = $self->_get_cipher_value($_, $xpc);
    my $digest_name  = $self->_get_digest_method($_, $xpc);
    my $oaep         = $self->_get_oaep_params($_, $xpc);
    my $mgf          = $self->_get_mgf($_, $xpc);

    return $self->_decrypt_key(
        $cipher_value,
        $algo,
        $digest_name,
        $oaep,
        $mgf,
    );
}

sub _get_encryption_algorithm {
    my $self = shift;
    my $node = shift;
    my $xpc  = shift;

    my $nodes = $xpc->findnodes('./xenc:EncryptionMethod/@Algorithm', $node);
    return $nodes->get_node(1)->getValue if $nodes->size;
    confess "Unable to determine encryption method algorithm from " . $node->nodePath;
}

sub _get_cipher_value {
    my $self = shift;
    my $node = shift;
    my $xpc  = shift;

    my $nodes = $xpc->findnodes('./xenc:CipherData/xenc:CipherValue', $node);
    return decode_base64($nodes->get_node(1)->textContent) if $nodes->size;
    confess "Unable to get the CipherValue from " . $node->nodePath;
}

sub _get_mgf {
    my $self = shift;
    my $node = shift;
    my $xpc  = shift;

    my $value = $xpc->findvalue('./xenc:EncryptionMethod/xenc11:MGF/@Algorithm', $node);
    return $value if $value;
    return;
}

sub _get_oaep_params {
    my $self = shift;
    my $node = shift;
    my $xpc  = shift;

    my $value = $xpc->findvalue('./xenc:EncryptionMethod/xenc:OAEPparams', $node);
    return decode_base64($value) if $value;
    return;
}

sub _get_digest_method {
    my $self = shift;
    my $node = shift;
    my $xpc  = shift;

    my $value = $xpc->findvalue(
        './xenc:EncryptionMethod/dsig:DigestMethod/@Algorithm', $node);
    return _assert_encryption_digest($value) if $value;
    return;
}


sub encrypt {
    my $self    = shift;
    my ($xml)   = @_;

    local $XML::LibXML::skipXMLDeclaration = $self->{ no_xml_declaration };

    # Create the EncryptedData node
    my ($encrypted) = $self->_create_encrypted_data_xml();

    my $dom = XML::LibXML->load_xml( string => $xml);

    my $xpc = XML::LibXML::XPathContext->new($encrypted);
    $xpc->registerNs('dsig', 'http://www.w3.org/2000/09/xmldsig#');
    $xpc->registerNs('xenc', 'http://www.w3.org/2001/04/xmlenc#');
    $xpc->registerNs('xenc11', 'http://www.w3.org/2009/xmlenc11#');
    $xpc->registerNs('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');

    # Encrypt the data an empty key is passed by reference to allow
    # the key to be generated at the same time the data is being encrypted
    my $key;
    my $method = $self->{data_enc_method};
    my $encrypteddata = $self->_EncryptData ($method, $dom->serialize(), \$key);

    # Encrypt the Key immediately after the data is encrypted.  It is passed by
    # reference to reduce the number of times that the unencrypted key is
    # stored in memory
    $self->_EncryptKey($self->{key_transport}, \$key);

    my $base64_key  = encode_base64($key);
    my $base64_data = encode_base64($encrypteddata);

    # Insert KeyName into the XML
    if (defined $self->{key_name} and $self->{key_name} ne '') {
        $encrypted = $self->_setKeyName($encrypted, $xpc, $self->{key_name});
    }

    # Insert OAEPparams into the XML
    if ($self->{oaep_params} ne '') {
        $encrypted = $self->_setOAEPparams($encrypted, $xpc, encode_base64($self->{oaep_params}));
    }

    # Insert Encrypted data into XML
    $encrypted = $self->_setEncryptedData($encrypted, $xpc, $base64_data);

    # Insert the Encrypted Key into the XML
    $self->_setKeyEncryptedData($encrypted, $xpc, $base64_key);

    return $encrypted->serialize();
}

sub _setEncryptionMethod {
    my $self    = shift;
    my $method  = shift;

    my %methods = (
                    'aes128-cbc'    => 'http://www.w3.org/2001/04/xmlenc#aes128-cbc',
                    'aes192-cbc'    => 'http://www.w3.org/2001/04/xmlenc#aes192-cbc',
                    'aes256-cbc'    => 'http://www.w3.org/2001/04/xmlenc#aes256-cbc',
                    'tripledes-cbc' => 'http://www.w3.org/2001/04/xmlenc#tripledes-cbc',
                    'aes128-gcm'    => 'http://www.w3.org/2009/xmlenc11#aes128-gcm',
                    'aes192-gcm'    => 'http://www.w3.org/2009/xmlenc11#aes192-gcm',
                    'aes256-gcm'    => 'http://www.w3.org/2009/xmlenc11#aes256-gcm',
                  );

    return exists($methods{$method}) ? $methods{$method} : $methods{'aes256-cbc'};
}

sub _setKeyName {
    my $self         = shift;
    my $context      = shift;
    my $xpc          = shift;
    my $keyname      = shift;

    my $node = $xpc->findnodes('//xenc:EncryptedKey/dsig:KeyInfo/dsig:KeyName', $context);

    $node->[0]->removeChildNodes();
    $node->[0]->appendText(defined $keyname ? $keyname : 'key_name');
    return $context;
}

sub _setOAEPparams {
    my $self         = shift;
    my $context      = shift;
    my $xpc          = shift;
    my $oaep_params  = shift;

    my $node = $xpc->findnodes('//xenc:EncryptedKey/xenc:EncryptionMethod/xenc:OAEPparams', $context);

    $node->[0]->removeChildNodes();
    $node->[0]->appendText($oaep_params);
    return $context;
}

sub _setOAEPAlgorithm {
    my $self    = shift;
    my $method  = shift;

    state $setOAEPAlgorithm = {
        'mgf1sha1'   => 'http://www.w3.org/2009/xmlenc11#mgf1sha1',
        'mgf1sha224' => 'http://www.w3.org/2009/xmlenc11#mgf1sha224',
        'mgf1sha256' => 'http://www.w3.org/2009/xmlenc11#mgf1sha256',
        'mgf1sha384' => 'http://www.w3.org/2009/xmlenc11#mgf1sha384',
        'mgf1sha512' => 'http://www.w3.org/2009/xmlenc11#mgf1sha512',
    };

    return $setOAEPAlgorithm->{$method} // $setOAEPAlgorithm->{'rsa-oaep-mgf1p'};
}

sub _getOAEPAlgorithm {
    my $self    = shift;
    my $method  = shift;

    state $OAEPAlgorithm = {
        'http://www.w3.org/2009/xmlenc11#mgf1sha1'   => 'SHA1',
        'http://www.w3.org/2009/xmlenc11#mgf1sha224' => 'SHA224',
        'http://www.w3.org/2009/xmlenc11#mgf1sha256' => 'SHA256',
        'http://www.w3.org/2009/xmlenc11#mgf1sha384' => 'SHA384',
        'http://www.w3.org/2009/xmlenc11#mgf1sha512' => 'SHA512',
    };

    return $OAEPAlgorithm->{$method} // 'SHA1';
}

sub _setOAEPDigest {
    my $self    = shift;
    my $method  = shift;

    state $OAEPDigest = {
        'sha1'      => 'http://www.w3.org/2000/09/xmldsig#sha1',
        'sha224'    => 'http://www.w3.org/2001/04/xmldsig-more#sha224',
        'sha256'    => 'http://www.w3.org/2001/04/xmlenc#sha256',
        'sha384'    => 'http://www.w3.org/2001/04/xmldsig-more#sha384',
        'sha512'    => 'http://www.w3.org/2001/04/xmlenc#sha512',
    };

    return $OAEPDigest->{$method} // $OAEPDigest->{'sha256'};
}

sub _getParamsAlgorithm {
    my $self    = shift;
    my $method  = shift;

    state $ParamsAlgorithm = {
        'http://www.w3.org/2000/09/xmldsig#sha1' => 'SHA1',
        'http://www.w3.org/2001/04/xmldsig-more#sha224' => 'SHA224',
        'http://www.w3.org/2001/04/xmlenc#sha256' => 'SHA256',
        'http://www.w3.org/2001/04/xmldsig-more#sha384' => 'SHA384',
        'http://www.w3.org/2001/04/xmlenc#sha512' => 'SHA512',
    };

    return $ParamsAlgorithm->{$method} // $ParamsAlgorithm->{'http://www.w3.org/2000/09/xmldsig#sha1'};
}

sub _setKeyEncryptionMethod {
    my $self    = shift;
    my $method  = shift;

    state $enc_methods = {
        'rsa-1_5'        => 'http://www.w3.org/2001/04/xmlenc#rsa-1_5',
        'rsa-oaep-mgf1p' => 'http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p',
        'rsa-oaep'       => 'http://www.w3.org/2009/xmlenc11#rsa-oaep',
    };

    return $enc_methods->{$method} // $enc_methods->{'rsa-oaep-mgf1p'};
}

sub _DecryptData {
    my $self            = shift;
    my $method          = shift;
    my $key             = shift;
    my $encrypteddata   = shift;

    my $method_vars = _assert_symmetric_algorithm($method);

    my $ivsize   = $method_vars->{ivsize};
    my $tagsize  = $method_vars->{tagsize};

    my $iv          = substr $encrypteddata, 0, $ivsize;
    my $encrypted   = substr $encrypteddata, $ivsize;

    # XML Encryption 5.2 Block Encryption Algorithms
    # The resulting cipher text is prefixed by the IV.
    if ($method !~ /gcm/ ){
        my $cbc = Crypt::Mode::CBC->new($method_vars->{modename}, 0);
        return $self->_remove_padding($cbc->decrypt($encrypted, $key, $iv));
    }

    my $gcm = Crypt::AuthEnc::GCM->new("AES", $key, $iv);

    # Note that GCM support for additional authentication
    # data is not used in the XML specification.
    my $tag = substr $encrypted, -$tagsize;
    $encrypted = substr $encrypted, 0, (length $encrypted) - $tagsize;
    my $plaintext = $gcm->decrypt_add($encrypted);

    die "Tag expected did not match returned Tag"
        unless $gcm->decrypt_done($tag);

    return $plaintext;
}

sub _EncryptData {
    my $self    = shift;
    my $method  = shift;
    my $data    = shift;
    my $key     = shift;


    my $method_vars = _assert_symmetric_algorithm($method);

    my $ivsize   = $method_vars->{ivsize};
    my $keysize  = $method_vars->{keysize};

    my $iv = random_bytes($ivsize);
    ${$key} = random_bytes($keysize);

    if ($method =~ /gcm/ ){
        my $gcm
            = Crypt::AuthEnc::GCM->new($method_vars->{modename}, ${$key}, $iv);

        # Note that GCM support for additional authentication
        # data is not used in the XML specification.
        my $encrypted = $gcm->encrypt_add($data);
        my $tag       = $gcm->encrypt_done();

        return $iv . $encrypted . $tag;
    }

    my $cbc = Crypt::Mode::CBC->new($method_vars->{modename}, 0);
    # XML Encryption 5.2 Block Encryption Algorithms
    # The resulting cipher text is prefixed by the IV.
    $data = $self->_add_padding($data, $ivsize);
    return $iv . $cbc->encrypt($data, ${$key}, $iv);
}

sub _decrypt {
    my $sub = shift;
    my $decrypt;
    eval { $decrypt = $sub->() };
    return $decrypt unless $@;
    return;
}

sub _decrypt_key {
    my $self        = shift;
    my $key         = shift;
    my $algo        = shift;
    my $digest_name = shift;
    my $oaep        = shift;
    my $mgf         = shift;

    if ($algo eq 'http://www.w3.org/2001/04/xmlenc#rsa-1_5') {
        return _decrypt(sub{$self->{key_obj}->decrypt($key, 'v1.5')});
    }

    if ($algo eq 'http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p') {
        return _decrypt(
            sub {
                if ($CryptX::VERSION lt 0.081) {
                    #print "Caller: _decrypt_key  rsa-oaep-mgf1p\n";
                    $self->{key_obj}->decrypt(
                        $key, 'oaep',
                        #$self->_getOAEPAlgorithm($mgf),
                        $digest_name // 'SHA1',
                        $oaep // '',
                    );
                } else {
                    #print "Caller: _decrypt_key  rsa-oaep-mgf1p\n";
                    #print "digest_name: ", $digest_name, "\n";
                    $self->{key_obj}->decrypt(
                        $key, 'oaep',
                        $mgf // 'SHA1',
                        $oaep // '',
                        $digest_name // 'SHA1',
                    );
                }
            }
        );
    }

    if ($algo eq 'http://www.w3.org/2009/xmlenc11#rsa-oaep') {
        return _decrypt(
            sub {
                if ($CryptX::VERSION lt 0.081) {
                    $self->{key_obj}->decrypt(
                        $key, 'oaep',
                        $self->_getOAEPAlgorithm($mgf),
                        $oaep // '',
                    );
                } else {
                    $self->{key_obj}->decrypt(
                        $key, 'oaep',
                        $self->_getOAEPAlgorithm($mgf),
                        $oaep // '',
                        $digest_name // '',
                    );
                }
            }
        );
    }

    die "Unsupported algorithm for key decryption: $algo";
}

sub _EncryptKey {
    my $self        = shift;
    my $keymethod   = shift;
    my $key         = shift;

    my $rsa_pub = $self->{cert_obj};

    # FIXME: this could use some refactoring and some simplfication
    if ($keymethod eq 'http://www.w3.org/2001/04/xmlenc#rsa-1_5') {
        ${$key} = $rsa_pub->encrypt(${$key}, 'v1.5');
    }
    elsif ($keymethod eq 'http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p') {
        if ($CryptX::VERSION lt 0.081) {
            ${$key} = $rsa_pub->encrypt(${$key}, 'oaep', 'SHA1', $self->{oaep_params});
        } else {
            my $oaep_label_hash = (defined $self->{oaep_label_hash} && $self->{oaep_label_hash} ne '') ?
                            $self->_getParamsAlgorithm($self->{oaep_label_hash}) : 'SHA1';
            ${$key} = $rsa_pub->encrypt(${$key}, 'oaep', 'SHA1', $self->{oaep_params}, $oaep_label_hash);
        }
    }
    elsif ($keymethod eq 'http://www.w3.org/2009/xmlenc11#rsa-oaep') {
        my $mgf_hash    = defined $self->{oaep_mgf_alg} ?
                            $self->_getOAEPAlgorithm($self->{oaep_mgf_alg}) : undef;
        if ($CryptX::VERSION lt 0.081) {
            ${$key} = $rsa_pub->encrypt(${$key}, 'oaep', $mgf_hash, $self->{oaep_params});
        } else {
            my $oaep_label_hash = (defined $self->{oaep_label_hash} && $self->{oaep_label_hash} ne '') ?
                            $self->_getParamsAlgorithm($self->{oaep_label_hash}) : $mgf_hash;
            ${$key} = $rsa_pub->encrypt(${$key}, 'oaep', $mgf_hash, $self->{oaep_params}, $oaep_label_hash);
        }
    } else {
        die "Unsupported algorithm for key encyption $keymethod}";
    }

    print "Encrypted key: ", encode_base64(${$key}) if $DEBUG;
}

sub _setEncryptedData {
    my $self         = shift;
    my $context      = shift;
    my $xpc          = shift;
    my $cipherdata   = shift;

    my $node = $xpc->findnodes('xenc:EncryptedData/xenc:CipherData/xenc:CipherValue', $context);

    $node->[0]->removeChildNodes();
    $node->[0]->appendText($cipherdata);
    return $context;
}

sub _setKeyEncryptedData {
    my $self         = shift;
    my $context      = shift;
    my $xpc          = shift;
    my $cipherdata   = shift;

    my $node;

    if ($xpc->findvalue('dsig:KeyInfo/dsig:RetrievalMethod/@Type', $context)
                eq 'http://www.w3.org/2001/04/xmlenc#EncryptedKey')
    {
        my $id = $xpc->findvalue('dsig:KeyInfo/dsig:RetrievalMethod/@URI', $context);
        $id    =~ s/#//g;

        my $keyinfo = $xpc->find('//*[@Id=\''. $id . '\']', $context);
        if (! $keyinfo ) {
            die "Unable to find EncryptedKey";
        }

        $node = $keyinfo->[0]->findnodes('//xenc:EncryptedKey/xenc:CipherData', $context)->[0];
    } else {
        $node = $xpc->findnodes('//dsig:KeyInfo/xenc:EncryptedKey/xenc:CipherData/xenc:CipherValue')->[0];
    }
    $node->removeChildNodes();
    $node->appendText($cipherdata);
}

sub _remove_padding {
    my $self    = shift;
    my $padded  = shift;

    my $len = length $padded;
    my $padlen = ord substr $padded, $len - 1;
    return substr $padded, 0, $len - $padlen;
}

sub _add_padding {
    my $self    = shift;
    my $data    = shift;
    my $blksize = shift;

    my $len = length $data;
    my $padlen = $blksize - ($len % $blksize);
    my @pad;
    my $n = 0;
    while ($n < $padlen -1 ) {
        $pad[$n] = 176 + int(rand(80));
        $n++;
    }

    return $data . pack ("C*", @pad, $padlen);
}

##
## _trim($string)
##
## Arguments:
##    $string:      string String to remove whitespace
##
## Returns: string  Trimmed String
##
## Trim the whitespace from the begining and end of the string
##
sub _trim {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

##
## _load_key($file)
##
## Arguments: $self->{ key }
##
## Returns: nothing
##
## Load the key and process it acording to its headers
##
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
        } elsif ( $text =~ m/BEGIN EC PRIVATE KEY/ ) {
            $self->_load_ecdsa_key( $text );
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

##
## _load_rsa_key($key_text)
##
## Arguments:
##    $key_text:    string RSA Private Key as String
##
## Returns: nothing
##
## Populate:
##   self->{KeyInfo}
##   self->{key_obj}
##   self->{key_type}
##
sub _load_rsa_key {
    my $self        = shift;
    my ($key_text)  = @_;

    eval {
        require Crypt::PK::RSA;
    };
    confess "Crypt::PK::RSA needs to be installed so that we can handle RSA keys." if $@;

    my $rsaKey = Crypt::PK::RSA->new(\$key_text );

    if ( $rsaKey ) {
        $self->{ key_obj }  = $rsaKey;
        $self->{ key_type } = 'rsa';

        if (!$self->{ x509 }) {
            my $keyhash = $rsaKey->key2hash();

            $self->{KeyInfo} = "<dsig:KeyInfo>
                                 <dsig:KeyValue>
                                  <dsig:RSAKeyValue>
                                   <dsig:Modulus>$keyhash->{N}</dsig:Modulus>
                                   <dsig:Exponent>$keyhash->{d}</dsig:Exponent>
                                  </dsig:RSAKeyValue>
                                 </dsig:KeyValue>
                                </dsig:KeyInfo>";
        }
    }
    else {
        confess "did not get a new Crypt::PK::RSA object";
    }
}

##
## _load_x509_key($key_text)
##
## Arguments:
##    $key_text:    string RSA Private Key as String
##
## Returns: nothing
##
## Populate:
##   self->{key_obj}
##   self->{key_type}
##
sub _load_x509_key {
    my $self        = shift;
    my $key_text    = shift;

    eval {
        require Crypt::OpenSSL::X509;
    };
    confess "Crypt::OpenSSL::X509 needs to be installed so that we
            can handle X509 Certificates." if $@;

    my $x509Key = Crypt::OpenSSL::X509->new_private_key( $key_text );

    if ( $x509Key ) {
        $x509Key->use_pkcs1_padding();
        $self->{ key_obj } = $x509Key;
        $self->{key_type} = 'x509';
    }
    else {
        confess "did not get a new Crypt::OpenSSL::X509 object";
    }
}

##
## _load_cert_file()
##
## Arguments: none
##
## Returns: nothing
##
## Read the file name from $self->{ cert } and
## Populate:
##   self->{key_obj}
##   $self->{KeyInfo}
##
sub _load_cert_file {
    my $self = shift;

    eval {
        require Crypt::OpenSSL::X509;
    };

    die "Crypt::OpenSSL::X509 needs to be installed so that we can handle X509 certs.\n" if $@;

    my $file = $self->{ cert };
    if (!-r $file) {
        die "Could not find certificate file $file";
    }
    open my $CERT, '<', $file  or die "Unable to open $file\n";
    my $text = '';
    local $/ = undef;
    $text = <$CERT>;
    close $CERT;

    my $cert = Crypt::PK::RSA->new(\$text);
    die "Could not load certificate from $file" unless $cert;

    $self->{ cert_obj } = $cert;
    my $cert_text = $cert->export_key_pem('public_x509');
    $cert_text =~ s/-----[^-]*-----//gm;
    $self->{KeyInfo} = "<dsig:KeyInfo><dsig:X509Data><dsig:X509Certificate>\n"._trim($cert_text)."\n</dsig:X509Certificate></dsig:X509Data></dsig:KeyInfo>";
    return;
}

sub _create_encrypted_data_xml {
    my $self    = shift;

    local $XML::LibXML::skipXMLDeclaration = $self->{ no_xml_declaration };
    my $doc = XML::LibXML::Document->new();

    my $xencns = 'http://www.w3.org/2001/04/xmlenc#';
    my $dsigns = 'http://www.w3.org/2000/09/xmldsig#';
    my $xenc11ns = 'http://www.w3.org/2009/xmlenc11#';

    my $encdata = $self->_create_node($doc, $xencns, $doc, 'xenc:EncryptedData',
                            {
                                Type    => 'http://www.w3.org/2001/04/xmlenc#Element',
                            }
                        );

    $doc->setDocumentElement ($encdata);

    my $encmethod = $self->_create_node(
                            $doc,
                            $xencns,
                            $encdata,
                            'xenc:EncryptionMethod',
                            {
                                Algorithm => $self->{data_enc_method},
                            }
                        );

    my $keyinfo = $self->_create_node(
                            $doc,
                            $dsigns,
                            $encdata,
                            'dsig:KeyInfo',
                        );

    my $enckey = $self->_create_node(
                            $doc,
                            $xencns,
                            $keyinfo,
                            'xenc:EncryptedKey',
                        );

    my $kencmethod = $self->_create_node(
                            $doc,
                            $xencns,
                            $enckey,
                            'xenc:EncryptionMethod',
                            {
                                Algorithm => $self->{key_transport},
                            }
                        );

    if ($self->{key_transport} eq 'http://www.w3.org/2009/xmlenc11#rsa-oaep' ||
        $self->{key_transport} eq 'http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p' &&
        $self->{oaep_label_hash}) {
        my $digestmethod = $self->_create_node(
                            $doc,
                            $dsigns,
                            $kencmethod,
                            'dsig:DigestMethod',
                            {
                                Algorithm => $self->{oaep_label_hash},
                            }
                        );
    };

    if ($self->{'oaep_params'} ne '') {
        my $oaep_params = $self->_create_node(
                            $doc,
                            $xencns,
                            $kencmethod,
                            'xenc:OAEPparams',
                        );
    };

    if ($self->{key_transport} eq 'http://www.w3.org/2009/xmlenc11#rsa-oaep' &&
        $self->{oaep_mgf_alg}) {
        my $oaepmethod = $self->_create_node(
                            $doc,
                            $xenc11ns,
                            $kencmethod,
                            'xenc11:MGF',
                            {
                                Algorithm => $self->{oaep_mgf_alg},
                            }
                        );
    };

    my $keyinfo2 = $self->_create_node(
                            $doc,
                            $dsigns,
                            $enckey,
                            'dsig:KeyInfo',
                        );

    if (defined $self->{key_name}) {
        my $keyname = $self->_create_node(
                            $doc,
                            $dsigns,
                            $keyinfo2,
                            'dsig:KeyName',
                        );
    };

    my $keycipherdata = $self->_create_node(
                            $doc,
                            $xencns,
                            $enckey,
                            'xenc:CipherData',
                        );

    my $keyciphervalue = $self->_create_node(
                            $doc,
                            $xencns,
                            $keycipherdata,
                            'xenc:CipherValue',
                        );

    my $cipherdata = $self->_create_node(
                            $doc,
                            $xencns,
                            $encdata,
                            'xenc:CipherData',
                        );

    my $ciphervalue = $self->_create_node(
                            $doc,
                            $xencns,
                            $cipherdata,
                            'xenc:CipherValue',
                        );

    return $doc;
}

sub _create_node {
    my $self        = shift;
    my $doc         = shift;
    my $nsuri       = shift;
    my $parent      = shift;
    my $name        = shift;
    my $attributes  = shift;

    my $node = $doc->createElementNS ($nsuri, $name);
    for (keys %$attributes) {
        $node->addChild (
            $doc->createAttribute (
            #$node->setAttribute (
                        $_ => $attributes->{$_}
                        )
            );
    }
    $parent->addChild($node);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Enc - XML::Enc Encryption Support

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    my $decrypter = XML::Enc->new(
        {
            key                => 't/sign-private.pem',
            no_xml_declaration => 1,
        },
    );
    $decrypted = $enc->decrypt($xml);

    my $encrypter = XML::Enc->new(
        {
            cert               => 't/sign-certonly.pem',
            no_xml_declaration => 1,
            data_enc_method    => 'aes256-cbc',
            key_transport      => 'rsa-1_5',

        },
    );
    $encrypted = $enc->encrypt($xml);

=head1 NAME

XML::Enc - XML Encryption

=head1 METHODS

=head2 new( ... )

Constructor. Creates an instance of the XML::Enc object

Arguments:

=over

=item B<key>

Filename of the private key to be used for decryption.

=item B<cert>

Filename of the public key to be used for encryption.

=item B<no_xml_declaration>

Do not return the XML declaration if true (1).  Return it if false (0).
This is useful for decrypting documents without the declaration such as
SAML2 Responses.

=item B<data_enc_method>

Specify the data encryption method to be used.  Supported methods are:

Used in encryption.  Optional.  Default method: aes256-cbc

=over

=item * L<tripledes-cbc|https://www.w3.org/TR/2002/REC-xmlenc-core-20021210/Overview.html#tripledes-cbc>

=item * L<aes128-cbc|https://www.w3.org/TR/2002/REC-xmlenc-core-20021210/Overview.html#aes128-cbc>

=item * L<aes192-cbc|https://www.w3.org/TR/2002/REC-xmlenc-core-20021210/Overview.html#aes192-cbc>

=item * L<aes256-cbc|https://www.w3.org/TR/2002/REC-xmlenc-core-20021210/Overview.html#aes256-cbc>

=item * L<aes128-gcm|https://www.w3.org/TR/xmlenc-core/#aes128-gcm>

=item * L<aes192-gcm|https://www.w3.org/TR/xmlenc-core/#aes192-gcm>

=item * L<aes256-gcm|https://www.w3.org/TR/xmlenc-core/#aes256-gcm>

=back

=item B<key_transport>

Specify the encryption method to be used for key transport.  Supported methods are:

Used in encryption.  Optional.  Default method: rsa-oaep-mgf1p

=over

=item * L<rsa-1_5|https://www.w3.org/TR/2002/REC-xmlenc-core-20021210/Overview.html#rsa-1_5>

=item * L<rsa-oaep-mgf1p|https://www.w3.org/TR/2002/REC-xmlenc-core-20021210/Overview.html#rsa-oaep-mgf1p>

=item * L<rsa-oaep|http://www.w3.org/2009/xmlenc11#rsa-oaep>

=back

=item B<oaep_mgf_alg>

Specify the Algorithm to be used for rsa-oaep.  Supported algorithms are:

Used in encryption.  Optional.  Default method: mgf1sha1

=over

=item * L<mgf1sha1|http://www.w3.org/2009/xmlenc11#mgf1sha1>

=item * L<mgf1sha224|http://www.w3.org/2009/xmlenc11#mgf1sha224>

=item * L<mgf1sha265|http://www.w3.org/2009/xmlenc11#mgf1sha256>

=item * L<mgf1sha384|http://www.w3.org/2009/xmlenc11#mgf1sha384>

=item * L<mgf1sha512|http://www.w3.org/2009/xmlenc11#mgf1sha512>

=back

=item B<oaep_params>

Specify the OAEPparams value to use as part of the mask generation function (MGF).
It is optional but can be specified for rsa-oaep and rsa-oaep-mgf1p EncryptionMethods.

It is base64 encoded and stored in the XML as OAEPparams.

If specified you MAY specify the oaep_label_hash that should be used.  You should note
that not all implementations support an oaep_label_hash that differs from that of the
MGF specified in the xenc11:MGF element or the default MGF1 with SHA1.

The oaep_label_hash is stored in the DigestMethod child element of the EncryptionMethod.

=item B<oaep_label_hash>

Specify the Hash Algorithm to use for the rsa-oaep label as specified by oaep_params.

The default is sha1.  Supported algorithms are:

=over

=item * L<sha1|http://www.w3.org/2000/09/xmldsig#sha1>

=item * L<sha224|http://www.w3.org/2001/04/xmldsig-more#sha224>

=item * L<sha256|http://www.w3.org/2001/04/xmlenc#sha256>

=item * L<sha384|http://www.w3.org/2001/04/xmldsig-more#sha384>

=item * L<sha512|http://www.w3.org/2001/04/xmlenc#sha512>

=back

=item B<key_name>

Specify a key name to add to the KeyName element.  If it is not specified then no
KeyName element is added to the KeyInfo

=back

=head2 decrypt( ... )

Main decryption function.

Arguments:

=over

=item B<xml>

XML containing the encrypted data.

=back

=head2 encrypt( ... )

Main encryption function.

Arguments:

=over

=item B<xml>

XML containing the plaintext data.

=back

=head1 AUTHOR

Timothy Legge <timlegge@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by TImothy Legge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
