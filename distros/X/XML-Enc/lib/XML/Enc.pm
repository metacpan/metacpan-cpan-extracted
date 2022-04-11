use strict;
use warnings;

package XML::Enc;
our $VERSION = '0.06'; # VERSION

# ABSTRACT: XML::Enc Encryption Support

use Carp;
use XML::LibXML;
use Crypt::OpenSSL::RSA;
use Crypt::Mode::CBC;
use Crypt::AuthEnc::GCM 0.062;
use MIME::Base64 qw/decode_base64 encode_base64/;
use Crypt::Random qw( makerandom_octet );

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS $DEBUG);

our $DEBUG = 0;


# Source: https://www.w3.org/TR/2002/REC-xmlenc-core-20021210/Overview.html#sec-Alg-Block
# 5.2.1 Triple DES - 64 bit Initialization Vector (IV) (8 bytes)
# 5.2.2 AES - 128 bit initialization vector (IV) (16 bytes)

my %encmethods = (
        'http://www.w3.org/2001/04/xmlenc#tripledes-cbc' => {
                                                            ivsize => 8,
                                                            keysize => 24,
                                                            modename => 'DES_EDE' },
        'http://www.w3.org/2001/04/xmlenc#aes128-cbc' => {
                                                            ivsize => '16',
                                                            keysize => 16,
                                                            modename => 'AES' },
        'http://www.w3.org/2001/04/xmlenc#aes192-cbc' => {
                                                            ivsize => '16',
                                                            keysize => 24,
                                                            modename => 'AES' },
        'http://www.w3.org/2001/04/xmlenc#aes256-cbc' => {
                                                            ivsize => '16',
                                                            keysize => 32,
                                                            modename => 'AES' },
        'http://www.w3.org/2009/xmlenc11#aes128-gcm' => {
                                                            ivsize   => '12',
                                                            keysize  => 16,
                                                            modename => 'AES',
                                                            tagsize  => 16 },
        'http://www.w3.org/2009/xmlenc11#aes192-gcm' => {
                                                            ivsize   => '12',
                                                            keysize  => 24,
                                                            modename => 'AES',
                                                            tagsize  => 16 },
        'http://www.w3.org/2009/xmlenc11#aes256-gcm' => {
                                                            ivsize   => '12',
                                                            keysize  => 32,
                                                            modename => 'AES',
                                                            tagsize  => 16 },
        );


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

    return $self;
}


sub decrypt {
    my $self    = shift;
    my ($xml)   = @_;

    die "You cannot decrypt XML without a private key." unless $self->{key};

    local $XML::LibXML::skipXMLDeclaration = $self->{ no_xml_declaration };

    my $doc = XML::LibXML->load_xml( string => $xml );

    my $xpc = XML::LibXML::XPathContext->new($doc);
    $xpc->registerNs('dsig', 'http://www.w3.org/2000/09/xmldsig#');
    $xpc->registerNs('xenc', 'http://www.w3.org/2001/04/xmlenc#');
    $xpc->registerNs('saml', 'urn:oasis:names:tc:SAML:2.0:assertion');

    my $data;

    for my $encryptednode ($xpc->findnodes('//xenc:EncryptedData')) {
        my $type         = $self->_getEncryptionType($xpc, $encryptednode);
        my $method       = $self->_getEncryptionMethod($xpc, $encryptednode);
        my $keymethod    = $self->_getKeyEncryptionMethod($xpc, $encryptednode);
        my $encryptedkey = $self->_getKeyEncryptedData($xpc, $encryptednode);

        # Decrypt the key using specified method
        my $key = $self->_DecryptKey($keymethod, decode_base64($encryptedkey));

        my $encrypteddata = $self->_getEncryptedData($xpc, $encryptednode);

        # Decrypt the data using the decrypted key
        $data = $self->_DecryptData($method, $key, decode_base64($encrypteddata));

        # Load the decrypted XML text content and replace the EncryptedData
        # in the original XML with the decrypted XML nodes
        if ($type eq 'http://www.w3.org/2001/04/xmlenc#Element') {
            # Check to see whether the decrypted data is really XML
            # xmlsec has uses Element for encrypted Content
            my $parser = XML::LibXML->new();
            my $newnode = eval { $parser->load_xml(string => $data)->findnodes('//*')->[0] };

            if (defined $newnode) {
                $encryptednode->addSibling($newnode);
                $encryptednode->unbindNode();
            }
        } else {
            # http://www.w3.org/2001/04/xmlenc#Content
            my $parent = $encryptednode->parentNode;
            $parent->removeChildNodes;
            $parent->appendText($data);
        }
    }

    return $doc->serialize();
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

    # Insert Encrypted data into XML
    $encrypted = $self->_setEncryptedData($encrypted, $xpc, $base64_data);

    # Insert the Encrypted Key into the XML
    $self->_setKeyEncryptedData($encrypted, $xpc, $base64_key);

    return $encrypted->serialize();
}

sub _getEncryptionType {
    my $self    = shift;
    my $xpc     = shift;
    my $context = shift;

    return $xpc->findvalue('@Type', $context)
}

sub _getEncryptionMethod {
    my $self    = shift;
    my $xpc     = shift;
    my $context = shift;

    return $xpc->findvalue('xenc:EncryptionMethod/@Algorithm', $context)
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

sub _getKeyEncryptionMethod {
    my $self    = shift;
    my $xpc     = shift;
    my $context = shift;

    if ($xpc->findvalue('dsig:KeyInfo/dsig:RetrievalMethod/@Type', $context)
                eq 'http://www.w3.org/2001/04/xmlenc#EncryptedKey')
    {
        my $id = $xpc->findvalue('dsig:KeyInfo/dsig:RetrievalMethod/@URI', $context);
        $id    =~ s/#//g;

        my $keyinfo = $xpc->find('//*[@Id=\''. $id . '\']', $context);
        if (! $keyinfo ) {
            die "Unable to find EncryptedKey";
        }
        return $keyinfo->[0]->findvalue('//xenc:EncryptedKey/xenc:EncryptionMethod/@Algorithm', $context);
    }
    return $xpc->findvalue('dsig:KeyInfo/xenc:EncryptedKey/xenc:EncryptionMethod/@Algorithm', $context)
}

sub _setKeyEncryptionMethod {
    my $self    = shift;
    my $method  = shift;

    my %methods = (
                    'rsa-1_5'           => 'http://www.w3.org/2001/04/xmlenc#rsa-1_5',
                    'rsa-oaep-mgf1p'    => 'http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p',
                );

    return exists($methods{$method}) ? $methods{$method} : $methods{'rsa-oaep-mgf1p'};
}

sub _DecryptData {
    my $self            = shift;
    my $method          = shift;
    my $key             = shift;
    my $encrypteddata   = shift;

    my $iv;
    my $encrypted;
    my $plaintext;

    my $ivsize   = $encmethods{$method}->{ivsize};
    my $tagsize  = $encmethods{$method}->{tagsize};

    $iv          = substr $encrypteddata, 0, $ivsize;
    $encrypted   = substr $encrypteddata, $ivsize;

    # XML Encryption 5.2 Block Encryption Algorithms
    # The resulting cipher text is prefixed by the IV.
    if (defined $encmethods{$method} & $method !~ /gcm/ ){
        my $cbc     = Crypt::Mode::CBC->new($encmethods{$method}->{modename}, 0);
        $plaintext  = $self->_remove_padding($cbc->decrypt($encrypted, $key, $iv));
    } elsif (defined $encmethods{$method} & $method =~ /gcm/ ){
        my $gcm     = Crypt::AuthEnc::GCM->new("AES", $key, $iv);

        # Note that GCM support for additional authentication
        # data is not used in the XML specification.
        my $tag     = substr $encrypted, - $tagsize;
        $encrypted  = substr $encrypted, 0, (length $encrypted) - $tagsize;
        $plaintext  = $gcm->decrypt_add($encrypted);
        if ( ! $gcm->decrypt_done($tag) ) {
            die "Tag expected did not match returned Tag";
        }
    } else {
        die "Unsupported Encryption Algorithm";
    }

    return $plaintext;
}

sub _EncryptData {
    my $self    = shift;
    my $method  = shift;
    my $data    = shift;
    my $key     = shift;

    my $cipherdata;
    my $ivsize  = $encmethods{$method}->{ivsize};
    my $keysize = $encmethods{$method}->{keysize};

    my $iv      = makerandom_octet ( Length => $ivsize);
    ${$key}     = makerandom_octet ( Length => $keysize);

    if (defined $encmethods{$method} & $method !~ /gcm/ ){
        my $cbc = Crypt::Mode::CBC->new($encmethods{$method}->{modename}, 0);
        # XML Encryption 5.2 Block Encryption Algorithms
        # The resulting cipher text is prefixed by the IV.
        $data       = $self->_add_padding($data, $ivsize);
        $cipherdata = $iv . $cbc->encrypt($data, ${$key}, $iv);
    } elsif (defined $encmethods{$method} & $method =~ /gcm/ ){
        my $gcm = Crypt::AuthEnc::GCM->new($encmethods{$method}->{modename}, ${$key}, $iv);

        # Note that GCM support for additional authentication
        # data is not used in the XML specification.
        my $encrypted   = $gcm->encrypt_add($data);
        my $tag         = $gcm->encrypt_done();

        $cipherdata     = $iv . $encrypted . $tag;
    } else {
        die "Unsupported Encryption Algorithm";
    }

    return $cipherdata;
}

sub _DecryptKey {
    my $self            = shift;
    my $keymethod       = shift;
    my $encryptedkey    = shift;

    if ($keymethod eq 'http://www.w3.org/2001/04/xmlenc#rsa-1_5') {
        $self->{key_obj}->use_pkcs1_padding;
    }
    elsif ($keymethod eq 'http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p') {
        $self->{key_obj}->use_pkcs1_oaep_padding;
    } else {
        die "Unsupported Key Encryption Method";
    }

    print "Decrypted key: ", encode_base64($self->{key_obj}->decrypt($encryptedkey)) if $DEBUG;
    return $self->{key_obj}->decrypt($encryptedkey);
}

sub _EncryptKey {
    my $self        = shift;
    my $keymethod   = shift;
    my $key         = shift;

    my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($self->{cert_obj}->pubkey);
    if ($keymethod eq 'http://www.w3.org/2001/04/xmlenc#rsa-1_5') {
        $rsa_pub->use_pkcs1_padding;
    }
    elsif ($keymethod eq 'http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p') {
        $rsa_pub->use_pkcs1_oaep_padding;
    } else {
        die "Unsupported Key Encryption Method";
    }

    print "Encrypted key: ", encode_base64(${$key}) if $DEBUG;
    ${$key} = $rsa_pub->encrypt(${$key});
}

sub _getEncryptedData {
    my $self    = shift;
    my $xpc     = shift;
    my $context = shift;

    return $xpc->findvalue('xenc:CipherData/xenc:CipherValue', $context);
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

sub _getKeyEncryptedData {
    my $self    = shift;
    my $xpc     = shift;
    my $context = shift;

    if ($xpc->findvalue('dsig:KeyInfo/dsig:RetrievalMethod/@Type', $context)
                eq 'http://www.w3.org/2001/04/xmlenc#EncryptedKey')
    {
        my $id = $xpc->findvalue('dsig:KeyInfo/dsig:RetrievalMethod/@URI', $context);
        $id    =~ s/#//g;

        my $keyinfo = $xpc->find('//*[@Id=\''. $id . '\']', $context);
        if (! $keyinfo ) {
            die "Unable to find EncryptedKey";
        }

        return $keyinfo->[0]->findvalue('//xenc:EncryptedKey/xenc:CipherData/xenc:CipherValue', $context);
    }

    return $xpc->findvalue('dsig:KeyInfo/xenc:EncryptedKey/xenc:CipherData/xenc:CipherValue', $context);
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
        require Crypt::OpenSSL::RSA;
    };
    confess "Crypt::OpenSSL::RSA needs to be installed so that we can handle RSA keys." if $@;

    my $rsaKey = Crypt::OpenSSL::RSA->new_private_key( $key_text );

    if ( $rsaKey ) {
        $rsaKey->use_pkcs1_padding();
        $self->{ key_obj }  = $rsaKey;
        $self->{ key_type } = 'rsa';

        if (!$self->{ x509 }) {
            my $bigNum = ( $rsaKey->get_key_parameters() )[1];
            my $bin = $bigNum->to_bin();
            my $exp = encode_base64( $bin, '' );

            $bigNum = ( $rsaKey->get_key_parameters() )[0];
            $bin = $bigNum->to_bin();
            my $mod = encode_base64( $bin, '' );
            $self->{KeyInfo} = "<dsig:KeyInfo>
                                 <dsig:KeyValue>
                                  <dsig:RSAKeyValue>
                                   <dsig:Modulus>$mod</dsig:Modulus>
                                   <dsig:Exponent>$exp</dsig:Exponent>
                                  </dsig:RSAKeyValue>
                                 </dsig:KeyValue>
                                </dsig:KeyInfo>";
        }
    }
    else {
        confess "did not get a new Crypt::OpenSSL::RSA object";
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

    confess "Crypt::OpenSSL::X509 needs to be installed so that we can handle X509 certs." if $@;

    my $file = $self->{ cert };
    if ( open my $CERT, '<', $file ) {
        my $text = '';
        local $/ = undef;
        $text = <$CERT>;
        close $CERT;

        my $cert = Crypt::OpenSSL::X509->new_from_string($text);
        if ( $cert ) {
            $self->{ cert_obj } = $cert;
            my $cert_text = $cert->as_string;
            $cert_text =~ s/-----[^-]*-----//gm;
            $self->{KeyInfo} = "<dsig:KeyInfo><dsig:X509Data><dsig:X509Certificate>\n"._trim($cert_text)."\n</dsig:X509Certificate></dsig:X509Data></dsig:KeyInfo>";
        }
        else {
            confess "Could not load certificate from $file";
        }
    }
    else {
        confess "Could not find certificate file $file";
    }

    return;
}

sub _create_encrypted_data_xml {
    my $self    = shift;

    local $XML::LibXML::skipXMLDeclaration = $self->{ no_xml_declaration };
    my $doc = XML::LibXML::Document->new();

    my $xencns = 'http://www.w3.org/2001/04/xmlenc#';
    my $dsigns = 'http://www.w3.org/2000/09/xmldsig#';

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

    my $keyinfo2 = $self->_create_node(
                            $doc,
                            $dsigns,
                            $enckey,
                            'dsig:KeyInfo',
                        );

    my $keyname = $self->_create_node(
                            $doc,
                            $dsigns,
                            $keyinfo2,
                            'dsig:KeyName',
                        );

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

version 0.06

=head1 SYNOPSIS

    my $decrypter = XML::Enc->new(
                                {
                                    key                         => 't/sign-private.pem',
                                    no_xml_declaration          => 1,
                                },
                            );
    $decrypted = $enc->decrypt($xml);

    my $encrypter = XML::Enc->new(
                                {
                                    cert                => 't/sign-certonly.pem',
                                    no_xml_declaration  => 1,
                                    data_enc_method     => 'aes256-cbc',
                                    key_transport       => 'rsa-1_5',

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

Used in encryption.  Optional.  Default method: rsa-1_5

=over

=item * L<rsa-1_5|https://www.w3.org/TR/2002/REC-xmlenc-core-20021210/Overview.html#rsa-1_5>

=item * L<rsa-oaep-mgf1p|https://www.w3.org/TR/2002/REC-xmlenc-core-20021210/Overview.html#rsa-oaep-mgf1p>

=back

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

This software is copyright (c) 2022 by TImothy Legge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
