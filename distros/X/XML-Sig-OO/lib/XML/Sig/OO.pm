package XML::Sig::OO;

our $VERSION="0.005";

use Modern::Perl;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MIME::Base64;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Crypt::OpenSSL::X509;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::DSA;
use Crypt::OpenSSL::VerifyX509;
use Digest::SHA   qw(sha1);
use Ref::Util qw( is_plain_hashref);
use Data::Result;
use Carp qw(croak);
use Scalar::Util qw(looks_like_number);
use namespace::clean;

=head1 NAME

XML::Sig::OO - Modern XML Signatured validation

=head1 SYNOPSIS

  use XML::Sig::OO;

  # Sign our xml
  my $s=new XML::Sig::OO(
    xml=>'<?xml version="1.0" standalone="yes"?><data><test ID="A" /><test ID="B" /></data>',
    key_file=>'rsa_key.pem'
    cert_file=>'cert.pem',
  );
  my $result=$s->sign;
  die "Failed to sign the xml, error was: $result" unless $result;

  my $xml=$result->get_data;
  # Example checking a signature
  my $v=new XML::Sig::OO(xml=>$xml);

  # validate our xml
  my $result=$v->validate;

  if($result) {
    print "everything checks out!\n";
  } else {
    foreach my $chunk (@{$result->get_data}) {
      my ($nth,$signature,$digest)=@{$chunk}{qw(nth signature digest)};

      print "Results for processing chunk $nth\n";
      print "Signature State: ".($signature ? "OK\n" : "Failed, error was $signature\n");
      print "Digest State: ".($digest ? "OK\n" : "Failed, error was $digest\n");
    }
  }

=head1 DESCRIPTION

L<XML::Sig::OO> is a project to create a stand alone perl module that does a good job creating and validating xml signatures.  At its core  This module is written around libxml2 better known as L<XML::LibXML>.

=head1 Multiple signatures and keys

In the case of signing multiple //@ID elements, it is possible to sign each chunk with a different key, in fact you can even use completly different key types.

  use Modern::Perl;
  use XML::Sig::OO;
  use File::Spec;
  use FindBin qw($Bin);
  use Crypt::OpenSSL::DSA;
  use Crypt::OpenSSL::RSA;

  # create our signign object
  my $s=new XML::Sig::OO(
    xml=>'<?xml version="1.0" standalone="yes"?><data><test ID="A" /><test ID="B" /></data>',
  );

  my $x=$s->build_xpath;

  # sign our first xml chunk with our rsa key!
  my $rsa_str=join '',IO::File->new(File::Spec->catfile($Bin,'x509_key.pem'))->getlines;
  my $rsa=Crypt::OpenSSL::RSA->new_private_key($rsa_str);
  $rsa->use_pkcs1_padding();
  my $cert_str=join '',IO::File->new(File::Spec->catfile($Bin,'x509_cert.pem'))->getlines;
  $s->sign_cert($rsa);
  $s->key_type('rsa');
  $s->cert_string($cert_str);
  my $result=$s->sign_chunk($x,1);
  die $result unless $result;

  # Sign our 2nd chunk with our dsa key
  my $dsa = Crypt::OpenSSL::DSA->read_priv_key(File::Spec->catfile($Bin,'dsa_priv.pem'));
  $s->cert_string(undef);
  $s->sign_cert($dsa);
  $s->key_type('dsa');
  $result=$s->sign_chunk($x,2);
  die $result unless $result;

  my ($node)=$x->findnodes($s->xpath_Root);
  my $xml=$node->toString;

  print "Our Signed XML IS: \n",$xml,"\n";
  # Example checking a signature
  my $v=new XML::Sig::OO(xml=>$xml);

  $result=$v->validate;
  die $result unless $result;

  print "Our signed and xml passes validation\n";

=head2 Working with Net::SAML2

L<Net::SAML2> has many problems when it comes to signature validation of xml strings.  This section documents how to use this module in place of the Net::SAML2 built ins.

  use Net::SAML2::Protocol::Assertion;
  use XML::Sig::OO;
  use MIME::Base64;

  # Lets assume we have a post binding response
  my $saml_response=.....

  my $xml=decode_base64($saml_response);

  my $v=XML::Sig::OO->new(xml=>$xml,cacert=>'idp_cert.pem');
  my $result=$v->validate;
  die $result unless $result;

  # we can now use the asertion knowing it was from our idp
  my $assertion=Net::SAML2::Protocol::Assertion->new_from_xml(xml=>$xml)

=head2 Encrypted keys

Although this package does not directly support encrypted keys, it is possible to use encrypted keys by loading and exporting them with the L<Crypt::PK::RSA> and L<Crypt::PK::DSA> packages.

=head1 Constructor options

=cut

=over 4

=item * xml=>'...'

The base xml string to validate or sign. This option is always required.

=cut

has xml=>(
  is=>'ro',
  isa=>Str,
  required=>1,
);

=item * cacert=>'/path/to/your/cacert.pem'

Optional, used to validate X509 certs.

=cut

has cacert=>(
  is=>'ro',
  isa=>sub { my ($f)=@_; croak "cacert must be a readable file" unless defined($f) && -r $f },
  required=>0,
);

=item * build_parser=>sub { return XML::LibXML->new() }

Callback that returns a new XML Parser

=cut

has build_parser=>(
  is=>'ro',
  isa=>CodeRef,
  default=>sub { sub { XML::LibXML->new() } },
);

=item * namespaces=>{ ds=>'http://www.w3.org/2000/09/xmldsig#', ec=>'http://www.w3.org/2001/10/xml-exc-c14n#'}

Contains the list of namespaces to set in our XML::LibXML::XPathContext object.

=cut

has namespaces=>(
  is=>'ro',
  isa=>HashRef,
  default=>sub {
    {
      ds=>'http://www.w3.org/2000/09/xmldsig#',
      ec=>'http://www.w3.org/2001/10/xml-exc-c14n#',
      samlp=>"urn:oasis:names:tc:SAML:2.0:protocol",
    }
  },
);

=item * digest_cbs=>{ ... }

Contains the digest callbacks.  The default handlers can be found in %XML::SIG::OO::DIGEST.

=cut

our %DIGEST=(
  'http://www.w3.org/2000/09/xmldsig#sha1'  => sub { my ($self,$content)=@_; $self->_get_digest(sha1 => $content) },
  'http://www.w3.org/2001/04/xmlenc#sha256' => sub { my ($self,$content)=@_; $self->_get_digest(sha256 => $content) },
  'http://www.w3.org/2001/04/xmlenc#sha512' => sub { my ($self,$content)=@_; $self->_get_digest(sha512 => $content) },
  'http://www.w3.org/2001/04/xmldsig-more#sha224' => sub { my ($self,$content)=@_; $self->_get_digest(sha224 => $content) },
  'http://www.w3.org/2001/04/xmldsig-more#sha384' => sub { my ($self,$content)=@_; $self->_get_digest(sha384 => $content) },
  'http://www.w3.org/2001/04/xmldsig-more#sha512' => sub { my ($self,$content)=@_; $self->_get_digest(sha512 => $content) },
  'http://www.w3.org/2001/04/xmldsig-more#sha1024' => sub { my ($self,$content)=@_; $self->_get_digest(sha1024 => $content) },
  'http://www.w3.org/2001/04/xmldsig-more#sha2048' => sub { my ($self,$content)=@_; $self->_get_digest(sha2048=> $content) },
  'http://www.w3.org/2001/04/xmldsig-more#sha3072' => sub { my ($self,$content)=@_; $self->_get_digest(sha3072=> $content) },
  'http://www.w3.org/2001/04/xmldsig-more#sha4096' => sub { my ($self,$content)=@_; $self->_get_digest(sha4096=> $content) },
);

=item * digest_method=>'http://www.w3.org/2000/09/xmldsig#sha1'

Sets the digest method to be used when signing xml

=cut

has digest_method=>(
  isa=>sub { exists $DIGEST{$_[0]} or croak "$_[0] is not a supported digest" },
  is=>'ro',
  default=>'http://www.w3.org/2000/09/xmldsig#sha1',
);

=item * key_type=>'rsa'

The signature method we will use

=cut

has key_type=>(
  isa=>sub { croak "unsuported key type: $_[0]" unless $_[0]=~ /^(?:dsa|rsa|x509)$/s },
  is=>'rw',
  required=>0,
  lazy=>1,
  default=>'x509',
);

has digest_cbs=>(
  isa=>HashRef,
  is=>'ro',
  default=>sub { return { %DIGEST} },
);

sub _get_digest {
  my ($self,$algo, $content) = @_;
  my $digest = Digest::SHA->can("${algo}_base64")->($content);
  while (length($digest) % 4) { $digest .= '=' }
  return $digest;
}

our %TUNE_CERT=(
  'http://www.w3.org/2000/09/xmldsig#dsa-sha1' => sub { _tune_cert(@_,'sha1') },
  'http://www.w3.org/2000/09/xmldsig#rsa-sha1' => sub { _tune_cert(@_,'sha1') },
  'http://www.w3.org/2001/04/xmldsig-more#rsa-sha224' => sub { _tune_cert(@_,'sha224') },
  'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256' => sub { _tune_cert(@_,'sha256') },
  'http://www.w3.org/2001/04/xmldsig-more#rsa-sha384' => sub { _tune_cert(@_,'sha384') },
  'http://www.w3.org/2001/04/xmldsig-more#rsa-sha512' => sub { _tune_cert(@_,'sha512') },  
  'http://www.w3.org/2001/04/xmldsig-more#rsa-sha1024' => sub { _tune_cert(@_,'sha1024') },  
  'http://www.w3.org/2001/04/xmldsig-more#rsa-sha2048' => sub { _tune_cert(@_,'sha2048') },  
  'http://www.w3.org/2001/04/xmldsig-more#rsa-sha3072' => sub { _tune_cert(@_,'sha3072') },  
  'http://www.w3.org/2001/04/xmldsig-more#rsa-sha4096' => sub { _tune_cert(@_,'sha4096') },  
);

=item * signature_method=>'http://www.w3.org/2000/09/xmldsig#rsa-sha1'

Sets the signature method.

=cut

has signature_method=>(
  isa=>Str,
  is=>'ro',
  default=>'http://www.w3.org/2000/09/xmldsig#rsa-sha1',
);

sub _tune_cert {
  my ($self,$cert,$alg)=@_;

  my $method="use_${alg}_hash";

  if($cert->can($method)) {
    $cert->$method();
  }
}

=item * tune_cert_cbs=>{ ...}

A collection of callbacks to tune a certificate object for signing

=cut

has tune_cert_cbs=>(
  isa=>HashRef,
  is=>'ro',
  default=>sub {
    return {%TUNE_CERT}
  }
);

=item * mutate_cbs=>{....}

Transform and Canonization callbacks.  The default callbacks are defined in %XML::Sig::OO::MUTATE.

Callbacks are usied in the following context

  $cb->($self,$xpath_element);

=cut

sub _build_canon_coderef {
  my ($method,$comment)=@_;
  return sub {
    my ($self,$x,$node)=@_;
    return $node->$method($comment);
  };
}

sub _envelope_transform {
  my ($self,$x,$node,$nth)=@_;

  my $xpath=$self->context($self->xpath_Signature,$nth);
  my ($target)=$x->findnodes($xpath,$node);
  $node->removeChild($target) if defined($target);
  return $node->toString;
}

our %MUTATE=(
  'http://www.w3.org/2000/09/xmldsig#enveloped-signature'=>\&_envelope_transform,
  'http://www.w3.org/TR/2001/REC-xml-c14n-20010315' => _build_canon_coderef('toStringC14N',0),
  'http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments' => _build_canon_coderef('toStringC14N',1),
  'http://www.w3.org/2006/12/xml-c14n11' => _build_canon_coderef('toStringC14N_v1_1',0),
  'http://www.w3.org/2006/12/xml-c14n11#WithComments' => _build_canon_coderef('toStringC14N_v1_1',1),
  'http://www.w3.org/2001/10/xml-exc-c14n#' => _build_canon_coderef('toStringEC14N',0),
  'http://www.w3.org/2001/10/xml-exc-c14n#WithComments' => _build_canon_coderef('toStringEC14N',1),
);

has mutate_cbs=>(
  isa=>HashRef,
  is=>'ro',
  default=>sub { return {%MUTATE} },
);

=back

=head2 Xpaths

The xpaths in this package are not hard coded, each xpath can be defined as an argument to the constructor.  Since xml can contain multiple elements with signatures or multiple id elements to sign, most xpaths are prefixed with the $nth signature

Some cases the xpaths are used in the following context:

  (/xpath)[$nth]

In special cases like finding a list of transforms or which key, signature, or digest:

  (//ds::Signature)[$nth]/xpath

=over 4

=item * xpath_SignatureValue=>//ds:SignatureValue

Xpath used to find the signature value.

=cut

has xpath_SignatureValue=>(
  isa=>Str,
  is=>'ro',
  default=>'//ds:SignatureValue',
);

=item * xpath_SignatureMethod=>'//ds:SignatureMethod/@Algorithm'

Xpath used to find the signature method algorithm.

=cut

has xpath_SignatureMethod=>(
  isa=>Str,
  is=>'ro',
  default=>'//ds:SignatureMethod/@Algorithm',
);

=item * xpath_CanonicalizationMethod=>'//ds:CanonicalizationMethod/@Algorithm'

Xpath used to find the list of canonicalization method(s).

=cut

has xpath_CanonicalizationMethod=>(
  is=>Str,
  is=>'ro',
  default=>'//ds:CanonicalizationMethod/@Algorithm',
);

=item * xpath_SignedInfo=>'//ds:SignedInfo'

Xpath used to find the singed info.

=cut

has xpath_SignedInfo=>(
  is=>'ro',
  isa=>Str,
  default=>'//ds:SignedInfo',
);

=item * xpath_Signature=>'//ds:Signature'

Xpath used to fetch the signature value

=cut

has xpath_Signature=>(
  is=>'ro',
  isa=>Str,
  default=>'//ds:Signature'
);

=item * xpath_Transforms=>//ds:Transforms

Xpath Transform path
=cut

has xpath_Transforms=>(
  isa=>Str,
  is=>'ro',
  default=>'//ds:Transforms',
);

=item * xpath_Transform=>'/ds:Transform/@Algorithm'

Xpath used to find the transform Algorithm

=cut

has xpath_Transform=>(
  isa=>Str,
  is=>'ro',
  default=>'/ds:Transform/@Algorithm'
);

=item * xpath_DigestValue=>'//ds:DigestValue'

Xpath used to fetch the digest value

=cut

has xpath_DigestValue=>(
  is=>'ro',
  isa=>Str,
  default=>'//ds:DigestValue',
);

=item * xpath_DigestMethod=>'//ds:DigestMethod/@Algorithm'

Xpath used to find the digest method.

=cut

has xpath_DigestMethod=>(
  is=>'ro',
  isa=>Str,
  default=>'//ds:DigestMethod/@Algorithm',
);

=item * xpath_DigestId=>'//ds:Reference/@URI'

Xpath used to find the id of the node that should contain our digest.

=cut

has xpath_DigestId=>(
  is=>'ro',
  isa=>Str,
  default=>'//ds:Reference/@URI',
);

=item * digest_id_convert_cb=>sub { my ($self,$xpath_object,$id)=@_;$id =~ s/^#//;return "//*[\@ID='$id']" }

Code ref that converts the xpath_DigestId into the xpath lookup ised to find the digest node

=cut

has digest_id_convert_cb=>(
  isa=>CodeRef,
  default=>sub { \&_default_digest_id_conversion },
  is=>'ro',

);

sub _default_digest_id_conversion {
  my ($self,$xpath_object,$id)=@_;
  $id=~ s/^#//s;
  return "//*[\@ID='$id']";
}

=item * xpath_ToSign=>'//[@ID]'

Xpath used to find what nodes to sign.

=cut

has xpath_ToSign=>(
  isa=>Str,
  is=>'ro',
  default=>'//*[@ID]',
);

=item * xpath_IdValue=>'//@ID'

Xpath used to find the value of the current id.

=cut

has xpath_IdValue=>(
  isa=>Str,
  is=>'ro',
  default=>'//@ID',
);

=item * xpath_Root=>'/'

Root of the document expath

=cut

has xpath_Root=>(
  isa=>Str,
  is=>'ro',
  default=>'/',
);

=back

=head3 XPaths related to certs

This section documents all xpaths/options related to certs.

=cut

=over 4

=item * xpath_x509Data=>'/ds:KeyInfo/ds:X509Data/ds:X509Certificate'

Xpath used to find the x509 cert value.  In reality the nth signature will be prepended to this xpath.

Actual xpath used:

  (//ds:Signature)[$nth]/ds:KeyInfo/ds:X509Data/ds:X509Certificate

=cut

has xpath_x509Data=>(
  is=>'ro',
  isa=>Str,
  default=>'/ds:KeyInfo/ds:X509Data/ds:X509Certificate',
);

=item * xpath_RSAKeyValue=>'/ds:KeyInfo/ds:KeyValue/ds:RSAKeyValue'

Xpath used to find the RSA value tree.

=cut

has xpath_RSAKeyValue=>(
  is=>'ro',
  isa=>Str,
  default=>'/ds:KeyInfo/ds:KeyValue/ds:RSAKeyValue',
);

=item * xpath_RSA_Modulus=>'/ds:KeyInfo/ds:KeyValue/ds:RSAKeyValue/ds:Modulus'

Xpath used to find the RSA Modulus.

=cut

has xpath_RSA_Modulus=>(
  is=>'ro',
  is=>'rw',
  default=>'/ds:KeyInfo/ds:KeyValue/ds:RSAKeyValue/ds:Modulus',
);

=item * xpath_RSA_Exponent=>'/ds:KeyInfo/ds:KeyValue/ds:RSAKeyValue/ds:Exponent'

Xpath used to find the RSA Exponent.

=cut

has xpath_RSA_Exponent=>(
  is=>'ro',
  is=>'rw',
  isa=>Str,
  default=>'/ds:KeyInfo/ds:KeyValue/ds:RSAKeyValue/ds:Exponent',
);

=item * xpath_DSAKeyValue=>'/ds:KeyInfo/ds:KeyValue/ds:DSAKeyValue'

Xpath used for DSA key tree discovery.

=cut

has xpath_DSAKeyValue=>(
 is=>'ro',
 isa=>Str,
 default=>'/ds:KeyInfo/ds:KeyValue/ds:DSAKeyValue',
);

=item * xpath_DSA_P=>'/ds:KeyInfo/ds:KeyValue/ds:DSAKeyValue/ds:P'

Xpath used to find DSA_P.

=cut

has xpath_DSA_P=>(
  is=>'ro',
  isa=>Str,
  default=>'/ds:KeyInfo/ds:KeyValue/ds:DSAKeyValue/ds:P',
);

=item * xpath_DSA_Q=>''

Xpath used to find DSA_Q.

=cut

has xpath_DSA_Q=>(
  is=>'ro',
  isa=>Str,
  default=>'/ds:KeyInfo/ds:KeyValue/ds:DSAKeyValue/ds:Q',
);

=item * xpath_DSA_G=>'/ds:KeyInfo/ds:KeyValue/ds:DSAKeyValue/ds:G'

Xpath used to find DSA_G.

=cut

has xpath_DSA_G=>(
  is=>'ro',
  isa=>Str,
  default=>'/ds:KeyInfo/ds:KeyValue/ds:DSAKeyValue/ds:G',
);

=item * xpath_DSA_Y=>'/ds:KeyInfo/ds:KeyValue/ds:DSAKeyValue/ds:Y'

Xpath used to find DSA_Y

=cut 

has xpath_DSA_Y=>(
  is=>'ro',
  isa=>Str,
  default=>'/ds:KeyInfo/ds:KeyValue/ds:DSAKeyValue/ds:Y',
);

=back

=head3 OO Signing Options

The following Signature options can be passed to the constructor object.

=over 4

=item * key_file=>'path/to/my.key'

Key file only used when signing.

=cut

has key_file=>(
  isa=>Str,
  required=>0,
  is=>'ro',
);

=item * envelope_method=>"http://www.w3.org/2000/09/xmldsig#enveloped-signature"

Sets the envelope method; This value most likely is the only valid value.

=cut

has envelope_method=>(
  isa=>Str,
  is=>'ro',
  default=>"http://www.w3.org/2000/09/xmldsig#enveloped-signature",
);

#=item * canon_method=>'http://www.w3.org/2001/10/xml-exc-c14n#'
=item * canon_method=>'http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments'

Sets the canonization method used when signing the code

=cut

has canon_method=>(
  isa=>Str,
  #default=>"http://www.w3.org/2001/10/xml-exc-c14n#",
  default=>"http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments",
  is=>'ro',
);

=item * tag_namespace=>'ds'

Default namespace of the tags being created.  This must be defined in $self->namespaces.

=cut

has tag_namespace=>(
  isa=>Str,
  default=>'ds',
  is=>'ro',
);

=item * sign_cert=>$cert_object

Optional: The Certificate object used to sign xml.  If this option is set it is recomended that you set the "key_type" option as well.

=cut

has sign_cert=>(
  isa=>Object,
  is=>'rw',
  required=>0,
  lazy=>1,
);

=item * cert_file=>'/path/to/cert.pem'

The path that contains the cert file used for signing.

=cut

has cert_file=>(
  isa=>sub {
    my ($file)=@_;
    croak "$file must be defined" unless defined($file);
    croak "$file must be readable" unless -r $file;
  },
  is=>'rw',
  required=>0,
  lazy=>1,
);

=item * cert_string=>undef

This optional argument lets you define the x509 pem text that will be used to generate the x509 portion of the xml.

=cut

has cert_string=>(
  is=>'rw',
  required=>0,
  lazy=>1,
);

=back

=cut

sub BUILD {
  my ($self)=@_;

  # sanity check dsa signature method
  croak 'dsa key types only work with signature_method: http://www.w3.org/2000/09/xmldsig#dsa-sha1'
    if $self->key_type eq 'dsa' && $self->signature_method ne 'http://www.w3.org/2000/09/xmldsig#dsa-sha1';


  croak "namespaces does not contain: ".$self->tag_namespace unless exists $self->namespaces->{$self->tag_namespace};
  croak $self->signature_method." is an unsupported signature method" unless exists $self->tune_cert_cbs->{$self->signature_method};
  if(defined($self->key_file) && !defined($self->sign_cert)) {
    my $result=$self->load_cert_from_file($self->key_file);
    croak $result unless $result;
    my ($key_type,$cert)=@{$result->get_data}{qw(type cert)};
    $self->sign_cert($cert);
    $self->key_type($key_type);
  }
}

=head1 OO Methods

=head2 my $xpath=$self->build_xpath(undef|$xml,{ns=>'url'}|undef);

Creates a new xpath object based on our current object state. 

=cut

sub build_xpath {
  my ($self,$xml,$ns)=@_;
  $xml=$self->xml unless defined($xml);
  $ns=$self->namespaces unless defined($ns);
  my $p=XML::LibXML->new(clean_namespaces=>1);
  my $dom = $p->parse_string( $xml);
  my $x=XML::LibXML::XPathContext->new($dom);
  while(my ($key,$value)=each %{$ns}) {
    $x->registerNs($key,$value);
  }
  return $x;
}

=head2 my $result=$self->validate;

Returns a Data::Result Object.  When true validation passed, when false it contains why validation failed.

A better use case would be this:

  my $result=$self->validate;

  if($result) {
    print "everything checks out\n";
  } else {
    foreach my $chunk (@{$result->get_data}) {
      my ($nth,$signature,$digest)=@{$chunk}{qw(nth signature digest)};

      print "Results for processing chunk $nth\n";
      print "Signature State: ".($signature ? "OK\n" : "Failed, error was $signature\n";
      print "Digest State: ".($digest ? "OK\n" : "Failed, error was $digest\n";
    }
  }

=cut

sub validate {
  my ($self)=@_;

  my $total=$self->build_xpath->findnodes($self->xpath_Signature)->size;

  my $list=[];
  my $result=Data::Result->new(data=>$list,is_true=>1);
  for(my $nth=1;$nth <= $total;++$nth) {
    my $sig=$self->verify_signature(undef,$nth);
    my $digest=$self->verify_digest(undef,$nth);
    $result->is_true(0) unless $sig && $digest;
    my $ref={
      nth=>$nth,
      signature=>$sig,
      digest=>$digest,
    };
    push @$list,$ref;
  }
  $result->is_true(0) if $#{$list}==-1;
  return $result;

}

=head2 my $result=$self->verify_digest($nth)

Returns a Data::Result object: when true, the signature was verified, when false it contains why it failed.

=cut

sub verify_digest {
  my ($self,$x,$nth)=@_;

  $x=$self->build_xpath unless defined($x);

  my $result=$self->get_digest_value($x,$nth);
  return $result unless $result;
  my $value=$result->get_data;

  $result=$self->get_digest_method($x,$nth);
  return $result unless $result;
  my $method=$result->get_data;

  $result=$self->get_digest_node($x,$nth);
  return $result unless $result;
  my $node=$result->get_data;

  $result=$self->do_transforms($x,$node,$nth);
  return $result unless $result;
  my $xml=$result->get_data;

  my $cmp=$self->digest_cbs->{$method}->($self,$xml);
  $cmp=~ s/\s+//sg;
  return new_false Data::Result("orginal digest: $value ne $cmp") unless $value eq $cmp;

  # if we get here our digest checks out
  return new_true Data::Result("Ok");
}

=head2 my $result=$self->get_transforms($xpath_object,$nth)

Returns a Data::Reslt object, when true it contains an array ref that contains each digest transform, when false it contains why it failed.

Please note, the xpath generate is a concatination of $self->context($self->xpath_Transforms,$nth).$self->xpath_Transform, so keep that in mind when trying to change how transforms are looked up.

=cut

sub get_transforms {
  my ($self,$x,$nth)=@_;

  my $xpath=$self->context($self->xpath_Transforms,$nth).$self->xpath_Transform;
  my $transforms=$x->find($xpath);
  my $data=[];
  foreach my $att ($transforms->get_nodelist) {
    push @$data,$att->value;
  }

  return new_false Data::Result("Failed to find transforms in xpath: $xpath") unless $#{$data}>-1;
  return new_true Data::Result($data);
}

=head2 my $result=$self->get_digest_node($xpath_object)

Returns a Data::Result Object, when true it contains the Digest Node, when false it contains why it failed.

=cut

sub get_digest_node {
  my ($self,$x,$nth)=@_;
  my ($id)=$x->findvalue($self->context($self->xpath_DigestId,$nth));
  return new_false Data::Result("Could not find our digest node id in xpath: ".$self->xpath_DigestId) unless defined($id);
  my $next_xpath=$self->digest_id_convert_cb->($self,$x,$id);

  my ($node)=$x->findnodes($next_xpath);
  return new_false Data::Result("Could not find our digest node in xpath: $next_xpath") unless defined($node);

  return new_true Data::Result($node);
}

=head2 my $result=$self->get_digest_method($xpath_object,$nth)

Returns a Data::Result Object, when true it contains the Digest Method

=cut

sub get_digest_method {
  my ($self,$x,$nth)=@_;
  my $xpath=$self->context($self->xpath_DigestMethod,$nth);
  my ($digest_value)=$x->findvalue($xpath);
  return new_false Data::Result("Failed to find Digest Method in xpath: $xpath") unless defined($digest_value);
  return new_false Data::Result("Unsupported Digest Method: $digest_value") unless exists $self->digest_cbs->{$digest_value};
  return new_true Data::Result($digest_value);
}

=head2 my $result=$self->get_digest_value($xpath_object,$nth)

Returns a Data::Result Object, when true it contains the Digest Value.

=cut

sub get_digest_value {
  my ($self,$x,$nth)=@_;
  my ($digest_value)=$x->findvalue($self->context($self->xpath_DigestValue,$nth));
  return new_false Data::Result("Failed to find Digest Value in xpath: ".$self->xpath_DigestValue) unless defined($digest_value);
  $digest_value=~ s/\s+//sg;
  return new_true Data::Result($digest_value);
}

=head2 my $result=$self->verify_signature($nth);

Returns a Data::Result Object, when true the signature was validated, when fails it contains why it failed.

=cut

sub verify_signature {
  my ($self,$x,$nth)=@_;
  $x=$self->build_xpath unless defined($x);

  my $pos=$self->context($self->xpath_Signature,$nth);
  my $x509_path=$pos.$self->xpath_x509Data;
  my $rsa_path=$pos.$self->xpath_RSAKeyValue;
  my $dsa_path=$pos.$self->xpath_DSAKeyValue;
  if(my $string=$x->findvalue($x509_path)) {
    return new_false Data::Result("Found more than one x509 node in xpath: ".$self->xpath_x509Data) unless defined($string);
    return $self->verify_x509_sig($x,$string,$nth);
  } elsif($x->findvalue($rsa_path)) {
    return $self->verify_rsa($x,$string,$nth);
  } elsif($x->findvalue($dsa_path)) {
    return $self->verify_dsa($x,$string,$nth);
  } else {
    return new_false Data::Result("Currently Unsupported certificate method");
  }
}

=head2 my $result=$self->verify_dsa($x,$string,$nth)

Returns a Data::Result object, when true it validated the DSA signature.

=cut

sub verify_dsa {
  my ($self,$x,$string,$nth)=@_;

  my $pos=$self->context($self->xpath_Signature,$nth);
  my $dsa_pub = Crypt::OpenSSL::DSA->new();

  foreach my $key (qw(p q g y)) {
    my $method="xpath_DSA_".uc($key);
    my $xpath=$pos.$self->$method();
    my $value=$x->findvalue($xpath);

    return new_false Data::Result("Did not find DSA $key in xpath: $xpath") unless defined($value);
    my $opt="set_$key";
    my $set=decode_base64(_trim($value));
    $dsa_pub->can($opt) ? $dsa_pub->$opt($set) : $dsa_pub->set_pub_key($set);
  }

  my $result=$self->tune_cert_and_get_sig($x,$nth,$dsa_pub);
  my $ref=$result->get_data;
  # DSA signatures are limited to a message body of 20 characters, so a sha1 digest is taken
  return new_true Data::Result("OK") if $dsa_pub->verify(sha1($ref->{xml}),$ref->{sig});

  return new_false Data::Result("Failed to validate DSA Signature");
}

=head2 my $xpath_string=$self->context($xpath,$nth)

Returns an xpath wrapped in the nth instance syntax.

Example

  my $xpath="//something"
  my $nth=2;

  my $xpath_string=$self->context($xpath,$nth);

  $xpath_string eq '(//something)[2]';


Note: if nth is not set it defaults to 1

=cut

sub context {
  my ($self,$xpath,$nth)=@_;
  $nth=1 unless looks_like_number($nth);
  return "($xpath)[$nth]";
}

=head2 my $result=$self->get_sig_canon($x,$nth)

Returns a Data::Result object, when true it contains the canon xml of the $nth signature node.

=cut

sub get_sig_canon {
  my ($self,$x,$nth)=@_;
  my $result=$self->get_signed_info_node($x,$nth);
  my $signed_info_node=$result->get_data;
  return $result unless $result;

  return $self->do_canon($x,$signed_info_node,$nth);
}

=head2 my $result=$self->verify_x509_sig($x,$string,$nth) 

Returns a Data::Result Object, when true the x509 signature was validated.

=cut

sub verify_x509_sig {
  my ($self,$x,$string,$nth)=@_;

  my $x509=$self->clean_x509($string);
  my $cert=Crypt::OpenSSL::X509->new_from_string($x509);

  if(defined($self->cacert)) {
    my $ca=Crypt::OpenSSL::VerifyX509->new($self->cacert);
    my $result;
    eval {$result=new_false Data::Result("Could not verify the x509 cert against ".$self->cacert) unless $ca->verify($cert)};
    if($@) {
      return new_false Data::Result("Error using cert file: ".$self->cacert."error was: $@");
    }
    return $result if defined($result);
  }

  my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($cert->pubkey);

  my $result=$self->tune_cert_and_get_sig($x,$nth,$rsa_pub);
  my $ref=$result->get_data;

  return Data::Result->new_false("x509 signature check failed, becase our generated signature did not match the one stored in the xml")  
    unless $rsa_pub->verify($ref->{xml},$ref->{sig});

  return new_true Data::Result("Ok");
}

=head2 my $result=$self->tune_cert_and_get_sig($x,$nth,$cert)

Returns a Data::Result object, when true it contains the following hashref

Structure:

  cert: the tuned cert
  sig:  the binary signature to verify
  xml:  the xml to be verified against the signature

=cut

sub tune_cert_and_get_sig {
  my ($self,$x,$nth,$cert)=@_;

  my $result=$self->get_signature_method($x,$nth,$cert);
  return $result unless $result;
  my $method=$result->get_data;

  $result=$self->tune_cert($cert,$method);
  return $result unless $result;

  $result=$self->get_sig_canon($x,$nth);
  return $result unless $result;
  my $xml=$result->get_data;

  $result=$self->get_signature_value($x,$nth);
  return $result unless $result;
  my $sig=$result->get_data;

  return new_true Data::Result({
    sig=>$sig,
    xml=>$xml,
    cert=>$cert,
  });
}

=head2 my $result=$self->verify_rsa($x,$nth)

Returns a Data::Result Object, when true the the rsa key verification passed.

=cut

sub verify_rsa {
  my ($self,$x,$nth)=@_;
  my $pos=$self->context($self->xpath_Signature,$nth);
  my $xpath=$pos.$self->xpath_RSA_Modulus;

  my $mod=_trim($x->findvalue($xpath));
  return new_false Data::Result("Failed to find rsa modulus in xpath: $xpath") if $mod=~ m/^\s*$/s;

  $xpath=$pos.$self->xpath_RSA_Exponent;
  my $exp=_trim($x->findvalue($xpath));
  return new_false Data::Result("Failed to find rsa exponent in xpath: $xpath") if $exp=~ m/^\s*$/s;

  my $m = Crypt::OpenSSL::Bignum->new_from_bin(decode_base64($mod));
  my $e = Crypt::OpenSSL::Bignum->new_from_bin(decode_base64($exp));

  my $rsa_pub = Crypt::OpenSSL::RSA->new_key_from_parameters( $m, $e );

  my $result=$self->tune_cert_and_get_sig($x,$nth,$rsa_pub);
  my $ref=$result->get_data;

  return Data::Result->new_false("rsa signature check failed, becase our generated signature did not match the one stored in the xml")  
    unless $rsa_pub->verify($ref->{xml},$ref->{sig});
  
  return new_true Data::Result("Ok");
}

=head2 my $result=$self->do_transforms($xpath_object,$node_to_transform,$nth_node);

Retruns a Data::Result Object, when true it contains the xml string of the context node.

=cut

sub do_transforms {
  my ($self,$x,$target,$nth)=@_;
  my $result=$self->get_transforms($x,$nth);
  return $result unless $result;
  my $todo=$result->get_data;
  my $xml;
  foreach my $transform (@{$todo}) {
    my $result=$self->transform($x,$target,$transform,$nth);
    return $result unless $result;
    $xml=$result->get_data;
  }
  return new_true Data::Result($xml);
}

=head2 my $result=$self->do_canon($xpath_object,$node_to_transform,$nth_node);

Returns a Data::Result Object, when true it contains the canonized string.

=cut

sub do_canon {
  my ($self,$x,$target,$nth)=@_;
  my $result=$self->get_canon($x,$nth);
  return $result unless $result;
  my $todo=$result->get_data;
  my $xml;
  foreach my $transform (@{$todo}) {
    my $result=$self->transform($x,$target,$transform,$nth);
    return $result unless $result;
    $xml=$result->get_data;
  }
  return new_true Data::Result($xml);
}

=head2 my $result=$self->get_canon($xpath_object,$nth)

Returns a Data::Result Object, when true it contains an array ref of the canon methods.

Special note, the xpath is generated as follows

  my $xpath=$self->context($self->xpath_SignedInfo,$nth).$self->xpath_CanonicalizationMethod;

=cut

sub get_canon {
  my ($self,$x,$nth)=@_;

  my $xpath=$self->context($self->xpath_SignedInfo,$nth).$self->xpath_CanonicalizationMethod;
  my $nodes=$x->find($xpath);
  my $data=[];
  foreach my $att ($nodes->get_nodelist) {
    push @$data,$att->value;
  }
  return new_false Data::Result("No canonization methods found in xpath: $xpath") unless $#{$data} >-1;
  return new_true Data::Result($data);
}

=head2 my $result=$self->get_signature_value($xpath_object,$nth)

Returns a Data::Result object, when true it contains the base64 decoded signature

=cut

sub get_signature_value {
  my ($self,$x,$nth)=@_;
  my ($encoded)=$x->findvalue($self->context($self->xpath_SignatureValue,$nth));
  return new_false Data::Result("Signature Value was not found in xpath: ".$self->xpath_SignatureValue) unless defined($encoded);

  $encoded=~ s/\s+//sg;
  return new_true Data::Result(decode_base64($encoded));
}

=head2 my $result=$self->get_signed_info_node($xpath_object,$nth);

Given $xpath_object, Returns a Data::Result when true it will contains the signed info node

=cut

sub get_signed_info_node {
  my ($self,$x,$nth)=@_;
  
  my ($node)=$x->findnodes($self->context($self->xpath_SignedInfo,$nth));
  return new_false Data::Result("Signature node(s) not found in xpath: ".$self->xpath_Signature) unless defined($node);

  # leave it up to our transform!
  return new_true Data::Result($node);

}

=head2 my $result=$self->get_signature_method($xpath_object,$nth_node,$cert|undef)

Returns a Data::Result object, when true it contains the SignatureMethod.  If $cert is passed in, it will cert the hashing mode for the cert

=cut

sub get_signature_method {
  my ($self,$x,$nth,$cert)=@_;

  my ($method_url)=$x->findvalue($self->context($self->xpath_SignatureMethod,$nth));
  return new_false Data::Result("SignatureMethod not found in xpath: ".$self->xpath_SignatureMethod) unless defined($method_url);

  return new_true Data::Result($method_url);
}

=head2 my $result=$self->tune_cert($cert,$method)

Returns a Data::Result Object, when true Sets the hashing method for the $cert object.

=cut

sub tune_cert {
  my ($self,$cert,$method)=@_;
  return new_false Data::Result("Unsupported hashing method: $method")  unless exists $self->tune_cert_cbs->{$method};

  $self->tune_cert_cbs->{$method}->($self,$cert);
  return new_true Data::Result;
}

=head2 my $x509=$self->clean_x509($string)

Converts a given string to an x509 certificate.

=cut

sub clean_x509 {
  my ($self,$cert)=@_;
  $cert =~ s/\s+//g;
  my @lines;
  while (length $cert > 64) {
    push @lines, substr $cert, 0, 64, '';
  }
  push @lines,$cert;
  $cert = join "\n", @lines;
  $cert = "-----BEGIN CERTIFICATE-----\n" . $cert . "\n-----END CERTIFICATE-----\n";
  return $cert;
}

=head2 my $result=$self->transform($xpath_object,$node,$transformType,$nth)

Given the $node XML::LibXML::Element and $transformType, returns a Data::Result object.  When true the call to $result->get_data will return the xml, when false it will contain a string that shows why it failed.

=cut 

sub transform {
  my ($self,$x,$node,$type,$nth)=@_;
  
  return new_false Data::Result("tansform of [$type] is not supported") unless exists $self->mutate_cbs->{$type};
  return new_true Data::Result($self->mutate_cbs->{$type}->($self,$x,$node,$nth));
}

=head2 my $array_ref=$self->transforms

Returns an ArrayRef that contains the list of transform methods we will use when signing the xml.

This list is built out of the following:

  0: $self->envelope_method
  1: $self->canon_method

=cut

sub transforms {
  my ($self)=@_;
  return [$self->envelope_method,$self->canon_method];
}

=head2 my $xml=$self->create_digest_xml($id,$digest)

Produces a text xml fragment to be used for an xml digest.

=cut

sub create_digest_xml {
  my ($self,$id,$digest)=@_;
  my $method=$self->digest_method;
  my @list;
  my $ns=$self->tag_namespace;
  my $transforms=$self->transforms;
  foreach my $transform (@{$transforms}) {
    push @list,
qq{                            <${ns}:Transform Algorithm="$transform" />};
  }
  $transforms=join "\n",@list;
  return qq{<${ns}:Reference URI="#$id">
                        <${ns}:Transforms>\n$transforms
                        </${ns}:Transforms>
                        <${ns}:DigestMethod Algorithm="$method" />
                        <${ns}:DigestValue>$digest</${ns}:DigestValue>
                    </${ns}:Reference>};
}

=head2 my $xml=$self->create_signedinfo_xml($digest_xml)

Produces text xml fragment to be used for an xml signature

=cut

sub create_signedinfo_xml {
  my ($self,$digest_xml) = @_;
  my $method=$self->signature_method;
  my $canon_method=$self->canon_method;
  my $xmlns=$self->create_xmlns;
  my $ns=$self->tag_namespace;
  return qq{<${ns}:SignedInfo $xmlns>
                <${ns}:CanonicalizationMethod Algorithm="$canon_method" />
                <${ns}:SignatureMethod Algorithm="$method" />
                $digest_xml
            </${ns}:SignedInfo>};
}

=head2 my $xmlns=$self->create_xmlns

Creates our common xmlns string based on our namespaces.

=cut

sub create_xmlns {
  my ($self)=@_;
  my @list;
  foreach my $key (sort keys %{$self->namespaces}) {
    my $value=$self->namespaces->{$key};
    push @list,qq{xmlns:${key}="$value"};
  }

  my $xmlns=join ' ',@list;
  return $xmlns;
}

=head2 my $xml=$self->create_signature_xml

Creates the signature xml for signing.

=cut

sub create_signature_xml {
  my ($self,$signed_info,$signature_value,$key_string)=@_;
  my $xmlns=$self->create_xmlns;
  my $ns=$self->tag_namespace;
  return qq{<${ns}:Signature $xmlns>
            $signed_info
            <${ns}:SignatureValue>$signature_value</${ns}:SignatureValue>
            $key_string
        </${ns}:Signature>};
}

=head2 my $result=$self->load_cert_from_file($filename)

Returns a Data::Result structure, when true it contains a hasref with the following elements:

  type: 'dsa|rsa|x509'
  cert: $cert_object

=cut

sub load_cert_from_file {
  my ($self,$file)=@_;
  return new_false Data::Result("file is not defined") unless defined($file);
  return new_false Data::Result("cannot read: $file") unless -r $file;

  my $io=IO::File->new($file,'r');
  return new_false Data::Result("Cannot open $file, error was $!") unless $io;
  my $text=join '',$io->getlines;
  return $self->detect_cert($text);
}

=head2 my $result=$self->detect_cert($text)

Returns a Data::Result object, when true it contains the following hashref

  type: 'dsa|rsa|x509'
  cert: $cert_object

=cut

sub detect_cert {
  my ($self,$text)=@_;
  if ($text =~ m/BEGIN ([DR]SA) PRIVATE KEY/s ) {

    if($1 eq 'RSA') {
      return $self->load_rsa_string($text);
    } else {
      return $self->load_dsa_string($text);
    }

  } elsif ( $text =~ m/BEGIN PRIVATE KEY/ ) {
    return $self->load_rsa_string($text); 
  } elsif ($text =~ m/BEGIN CERTIFICATE/) {
    return $self->load_x509_string($text);
  } else {
    return new_false Data::Result("Unsupported key type");
  }
}

=head2 my $result=$self->load_rsa_string($string)

Returns a Data::Result object, when true it contains the following hashref:

  type: 'rsa'
  cert: $cert_object

=cut

sub load_rsa_string {
  my ($self,$str)=@_;
  my $rsaKey = Crypt::OpenSSL::RSA->new_private_key( $str );
  return new_false Data::Result("Failed to parse rsa key") unless $rsaKey;
  $rsaKey->use_pkcs1_padding();
  return new_true Data::Result({cert=>$rsaKey,type=>'rsa'});
}

=head2 my $result=$self->load_x509_string($string)

Returns a Data::Result object, when true it contains the following hashref:

  type: 'x509'
  cert: $cert_object

=cut

sub load_x509_string {
  my ($self,$str)=@_;
  my $x509Key = Crypt::OpenSSL::X509->new_from_string( $str );
  return new_false Data::Result("Failed to parse x509 cert") unless $x509Key;
  return new_true Data::Result({cert=>$x509Key,type=>'x509'});
}

=head2 my $result=$self->load_dsa_string($string)

Returns a Data::Result object, when true it contains the following hashref:

  type: 'dsa'
  cert: $cert_object

=cut

sub load_dsa_string {
  my ($self,$str)=@_;
  my $dsa_key = Crypt::OpenSSL::DSA->read_priv_key_str( $str );
  return new_false("Failed to parse dsa key") unless $dsa_key;
  return new_true Data::Result({cert=>$dsa_key,type=>'dsa'});
}

=head2 my $result=$self->get_xml_to_sign($xpath_object,$nth)

Returns a Data::Result object, when true it contains the xml object to sign.

=cut

sub get_xml_to_sign {
  my ($self,$x,$nth)=@_;
  my $xpath=$self->context($self->xpath_ToSign,$nth);
  my ($node)=$x->findnodes($xpath);

  return new_false Data::Result("Failed to find xml to sign in xpath: $xpath") unless defined($node);
  return new_true Data::Result($node);
}

=head2 my $result=$self->get_signer_id($xpath_object,$nth)

Returns a Data::Result object, when true it contains the id value

=cut

sub get_signer_id {
  my ($self,$x,$nth)=@_;
  my $xpath=$self->context($self->xpath_IdValue,$nth);
  my ($node)=$x->findvalue($xpath);
  return new_false Data::Result("Failed to find id value in xpath: $xpath") unless defined($node);
  return new_true Data::Result($node);
}

=head2 my $result=$self->sign

Returns a Data::Result Object, when true it contains the signed xml string.

=cut

sub sign {
  my ($self)=@_;
  my $x=$self->build_xpath;

  return new_false Data::Result("sign_cert object is not defined") unless defined($self->sign_cert);

  my $total=$x->findnodes($self->xpath_ToSign)->size;
  return new_false Data::Result("No xml found to sign") if $total==0;
  foreach(my $nth=1;$nth <=$total;++$nth) {
    my $result=$self->sign_chunk($x,$nth);
    return $result unless $result;
  }
  my ($root)=$x->findnodes($self->xpath_Root);

  return new_true Data::Result($root->toString);
}

=head2 my $result=$self->sign_chunk($xpath_object,$nth)

Returns a Data::Result object, when true, the nth element with //@ID was signed and updated in $xpath_object.  This method provides absolute granular control over what node is signed. 

=cut

sub sign_chunk {
  my ($self,$x,$nth)=@_;

  my $result=$self->get_xml_to_sign($x,$nth);
  return $result unless $result;
  my $node_to_sign=$result->get_data;

  $result=$self->get_signer_id($x,$nth);
  return $result unless $result;
  my $id=$result->get_data;

  my $digest_canon=$self->mutate_cbs->{$self->canon_method}->($self,$x,$node_to_sign,$nth);
  my $digest=$self->digest_cbs->{$self->digest_method}->($self,$digest_canon);

  my $digest_xml    = $self->create_digest_xml( $id,$digest );
  my $signedinfo_xml = $self->create_signedinfo_xml($digest_xml);
  my $p= XML::LibXML->new();

  # fun note, we have to append the child to get it to canonize correctly
  my $signed_info=$p->parse_balanced_chunk($signedinfo_xml);
  $node_to_sign->appendChild($signed_info);
  $result=$self->get_signed_info_node($x,$nth);
  return $result unless $result;
  $signed_info=$result->get_data;

  my $canon;
  foreach my $method (@{$self->transforms}) {
    $result=$self->transform($x,$signed_info,$method,$nth);
    return $result unless $result;
    $canon=$result->get_data;
  }

  # now we need to remove the child to contnue on
  $node_to_sign->removeChild($signed_info);

  my $sig;
  my $cert=$self->sign_cert;
  if ($self->key_type eq 'dsa') {
    # DSA only permits the signing of 20 bytes or less, hence the sha1
    my $raw= $cert->sign( sha1($canon) );
    $sig=encode_base64( $raw, "\n" );
  } elsif($self->key_type eq 'rsa') {
    my $result=$self->tune_cert($cert,$self->signature_method);
    return $result unless $result;
    my $raw= $cert->sign( $canon );
    $sig=encode_base64( $raw, "\n" );
  }
  my $method="create_".$self->key_type."_xml";
  my $key_xml=$self->$method($cert);
  my $signed_xml=$self->create_signature_xml($signed_info->toString,$sig,$key_xml);
  my $signed_frag=$p->parse_balanced_chunk($signed_xml);
  $node_to_sign->appendChild($signed_frag);
  return new_true Data::Result("OK");
}

=head2 my $xml=$self->create_x509_xml($cert)

Creates the xml from the Certificate Object.

=cut

sub create_x509_xml {
  my ($self,$cert)=@_;
  my $cert_text = $cert->as_string;
  return $self->build_x509_xml($cert_text);
}

=head2 my $xml=$self->build_x509_xml($encoded_key)

Given the base64 encoded key, create a block of x509 xml.

=cut

sub build_x509_xml {
  my ($self,$cert_text)=@_;
  my $ns=$self->tag_namespace;
  $cert_text =~ s/-----[^-]*-----//gm;
  return "<${ns}:KeyInfo><${ns}:X509Data><${ns}:X509Certificate>\n"._trim($cert_text)."\n</${ns}:X509Certificate></${ns}:X509Data></${ns}:KeyInfo>";
}

=head2 my $result=$self->find_key_cert

Returns a Data::Result Object, when true it contains the x509 cert xml.

=cut

sub find_key_cert {
  my ($self)=@_;
  if(defined(my $file=$self->cert_file)) {
    my $result=$self->load_cert_from_file($file);
    if($result) {
      my $str=_trim($result->get_data->{cert}->as_string);
      return new_true Data::Result($self->build_x509_xml($str));
    } else {
      return $result;
    }
  } elsif(defined($self->cert_string)) {
      return new_true Data::Result($self->build_x509_xml(_trim($self->cert_string)));
  }

  return new_false Data::Result("no cert found");
}

=head2 my $xml=$self->create_rsa_xml($cert)

Creates the xml from the Certificate Object.

=cut

sub create_rsa_xml {
  my ($self,$rsaKey)=@_;

  my $result=$self->find_key_cert;
  return $result->get_data if $result;

  my $bigNum = ( $rsaKey->get_key_parameters() )[1];
  my $bin = $bigNum->to_bin();
  my $exp = encode_base64( $bin, '' );
  $bigNum = ( $rsaKey->get_key_parameters() )[0];
  $bin = $bigNum->to_bin();
  my $mod = encode_base64( $bin, '' );
  my $ns=$self->tag_namespace;

  return "<${ns}:KeyInfo>
              <${ns}:KeyValue>
                 <${ns}:RSAKeyValue>
                    <${ns}:Modulus>$mod</${ns}:Modulus>
                    <${ns}:Exponent>$exp</${ns}:Exponent>
                 </${ns}:RSAKeyValue>
              </${ns}:KeyValue>
            </${ns}:KeyInfo>";
}

=head2 my $xml=$self->create_dsa_xml($cert)

Creates the xml for the Key Object.

=cut

sub create_dsa_xml {
  my ($self,$dsa_key)=@_;

  my $g=encode_base64( $dsa_key->get_g(), '' );
  my $p=encode_base64( $dsa_key->get_p(), '' );
  my $q=encode_base64( $dsa_key->get_q(), '' );
  my $y=encode_base64( $dsa_key->get_pub_key(), '' );

  my $ns=$self->tag_namespace;
  return "<${ns}:KeyInfo>
                             <${ns}:KeyValue>
                              <${ns}:DSAKeyValue>
                               <${ns}:P>$p</${ns}:P>
                               <${ns}:Q>$q</${ns}:Q>
                               <${ns}:G>$g</${ns}:G>
                               <${ns}:Y>$y</${ns}:Y>
                              </${ns}:DSAKeyValue>
                             </${ns}:KeyValue>
                            </${ns}:KeyInfo>";
}

sub _trim {
  my ($str)=@_;
  $str=~ s/(?:^\s+|\s+$)//sg;
  return $str;
}

=head1 Limitations

This package currently has some limitations.

=head2 Supported Key Types and formats for signing/validation

Currently this module only supports RSA and DSA keys in pem format.

=head2 CaCert Validation

Currently CaCert validation only works with RSA keys.

=head1 Credits

This code is based on the following modules: L<XML::Sig>, L<Net::SAML2::XML::Sig>, L<Authen::NZRealMe::XMLSig>, and L<Mojo::XMLSig> and would not exist today withot them.

=head1 Bugs

Currently there are no known bugs, but if any are found please report them on our github project.  Patches and pull requests are welcomed!

L<https://github.com/akalinux/xml-sig-oo>

=head1 Author

AKALINUX <AKALINUX@CPAN.ORG>

=cut

1;
