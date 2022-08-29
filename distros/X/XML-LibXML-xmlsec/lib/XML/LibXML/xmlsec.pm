package XML::LibXML::xmlsec;

use 5.016003;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

use XML::LibXML;
use Scalar::Util qw(blessed);
use MIME::Base64;
use List::Util qw( first );

use enum qw( xmlSecKeyDataFormatUnknown=0
    xmlSecKeyDataFormatBinary
    xmlSecKeyDataFormatPem
    xmlSecKeyDataFormatDer
    xmlSecKeyDataFormatPkcs8Pem
    xmlSecKeyDataFormatPkcs8Der
    xmlSecKeyDataFormatPkcs12
    xmlSecKeyDataFormatCertPem
    xmlSecKeyDataFormatCertDer
);

use enum qw(xmlSecDSigStatusUnknown=0
   xmlSecDSigStatusSucceeded
   xmlSecDSigStatusInvalid
   );

#This constants will be used to filter dumped keys
use constant xmlSecKeyDataTypeUnknown => 0x0000;
use constant xmlSecKeyDataTypeNone => xmlSecKeyDataTypeUnknown;
use constant xmlSecKeyDataTypePublic => 0x0001;
use constant xmlSecKeyDataTypePrivate => 0x0002;
use constant xmlSecKeyDataTypeSymmetric => 0x0004;
use constant xmlSecKeyDataTypeSession => 0x0008;
use constant xmlSecKeyDataTypePermanent => 0x0010;
use constant xmlSecKeyDataTypeTrusted => 0x0100;
use constant xmlSecKeyDataTypeSession => 0x0008;
use constant xmlSecKeyDataTypeAny => 0xFFFF;

our @ISA = qw(Exporter);

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('XML::LibXML::xmlsec', $VERSION);


sub new() {
   my $class=shift();
   my $self= bless {}, $class;
   my $ret=$self->InitPerlXmlSec();
   die "Can't initializa xmlsec engine $ret" unless ($ret);

   my $km=$self->InitKeyMgr();
   die "Can't initialize xmlsec KeyManager" unless ($km);
   $self->{_keymgr}=$km;

   return $self;
}

sub _base64decode($$) {

   my $self=shift();
   my $data=shift();

   my $s='';

   for (split /\n/, $data) {
      next if ( /^---/);
      $s .= $_;
   }

   return decode_base64($s);
}


sub loadpkey() {

   my $self=shift();
   my %options=@_;

   my $secret='';
   my $name='';
   my $file;
   my $ret;

   $secret=$options{secret} if (exists $options{secret});

   if (exists $options{name}) {
      $name=$options{name};
   } else {
      $name= 'noname';
   }

   if (exists $options{PEM} && $options{PEM} =~ /^-+BEGIN/) {
      $ret= $self->xmlSecKeyLoadString($self->{_keymgr},$options{PEM},$secret,$name,xmlSecKeyDataFormatPem);
   } elsif (exists $options{PEM}) {
      $file=$options{PEM};
      croak "Can't access PEM file $file" unless (-r $file);
      $ret= $self->XmlSecKeyLoad($self->{_keymgr},$file,$secret,$name,xmlSecKeyDataFormatPem);
   }

   if (exists $options{DER}) {
      $file=$options{DER};
      croak "Can't access DER file $file" unless (-r $file);
      $ret= $self->XmlSecKeyLoad($self->{_keymgr},$file,$secret,$name,xmlSecKeyDataFormatDer);
   }

   my $pfx;

   # PKCS12, PFX, P12 are equivalent
   $pfx= $options{PKCS12} if (exists $options{PKCS12});
   $pfx= $options{PFX} if (exists $options{PFX});
   $pfx= $options{P12} if (exists $options{P12});

   if ($pfx) {
      croak "Can't access PKCS12 file $pfx" unless (-r $pfx);
      $ret= $self->XmlSecKeyLoad($self->{_keymgr},$pfx,$secret,$name,xmlSecKeyDataFormatPkcs12);
   }

   return $ret;

}


sub loadcert() {
   
   my $self=shift();
   my %options=@_;

   my $name;

   if (exists $options{name}) {
      $name=$options{name};
   } else {
      $name= 'noname';
   }

   my $file;
   my $format;
   if (exists $options{PEM}) {
      $file=$options{PEM};
      $format=xmlSecKeyDataFormatCertPem;
   }

   if (exists $options{DER}) {
      $file=$options{DER};
      $format=xmlSecKeyDataFormatCertDer;
   }

   my $pfx;
   # PKCS12, PFX, P12 are equivalent
   $pfx= $options{PKCS12} if (exists $options{PKCS12});
   $pfx= $options{PFX} if (exists $options{PFX});
   $pfx= $options{P12} if (exists $options{P12});

   if ($pfx) {
      $file=$pfx;
      $format=xmlSecKeyDataFormatPkcs12;
   }

   my $secret=0;
   $secret= $options{secret} if (exists $options{secret});

   if ($file =~ /^---/) {
      $self->{x509}=$file;
      return $self->KeyCertLoadString($self->{_keymgr},$name,$secret,$file,$format);
   } else {

      croak "Can't access certificate file $file" unless (-r $file);
      open my $fh, '<',$file;
      $self->{x509}=read $fh, my $file_content, -s $fh;
      close $fh;
      return $self->KeyCertLoad($self->{_keymgr},$name,$secret,$file,$format);
   }
}


sub signdoc() {

   my $self=shift();
   my $doc=shift();
   my %options=@_;

   my $id;
   my $id_attr='id';
   my $id_node;
   my $start;

   $id=$options{'id'} if (exists $options{id});
   $id_attr=$options{'id-attr'} if (exists $options{'id-attr'});
   $id_node=$options{'id-node'} if (exists $options{'id-node'});
   $start=$options{'node'} if (exists $options{'node'});
   
   unless ($id_node) {
      $id_node=$doc->documentElement->nodeName;
   }
   $self->xmlSecIdAttrTweak($doc,$id_attr,$id_node);

   my $r;
   if ($start) {
      $r=$self->XmlSecSign($doc,$self->{_keymgr},$start);
   } else {
      $start=($doc->findnodes("//$id_node\[\@$id_attr='$id']"))[0];
      $r=$self->XmlSecSignDoc($doc,$self->{_keymgr},$id);
   }

   return $doc unless ($self->{x509});

   my $x509='';
   for (split /\n/, $self->{x509}) {
      next if ( /^---/);
      $x509 .= "$_\n";
   }

   for ($start->parentNode->findnodes('ds:Signature/ds:KeyInfo/ds:X509Data')) {
      
      #Si aquí no hay nada, le inyecto el x509
      if (! $_->hasChildNodes || $_->textContent =~ /^\s+$/ ) {
         $_->appendTextChild('X509Certificate',$x509);
      }      
   }

   return $doc;
}

sub verifydoc($$%) {
   my $self=shift();
   my $doc=shift();
   my %options=@_;

   my $id;
   my $id_attr='id';
   my $id_node;
   my $start;

   $id=$options{'id'} if (exists $options{id});
   $id_attr=$options{'id-attr'} if (exists $options{'id-attr'});
   $id_node=$options{'id-node'} if (exists $options{'id-node'});
   $start=$options{'node'} if (exists $options{'node'});

   unless ($id_node) {
      $id_node=$doc->documentElement->nodeName;
   }
   $self->xmlSecIdAttrTweak($doc,$id_attr,$id_node);

   my $r;
   $r=$self->XmlSecVerify($doc,$self->{_keymgr},$id);

   if ($r == xmlSecDSigStatusSucceeded) {
	   return 1;
   } else {
	   return 0;
   }
}

sub savekeys($$$) {

   my $self=shift();
   my $file=shift();
   my $type=shift();

   return $self->_KeysStoreSave($self->{_keymgr},$file,$type);
}

sub loadkeys($$$) {

   my $self=shift();
   my $file=shift();

   return $self->_KeysStoreLoad($self->{_keymgr},$file);
}

sub AllowedClass($$) {

   my $self=shift();
   my $id=shift();

   my @AllowedClass=qw(
xmlSecTransformDsaSha1Id
xmlSecTransformDsaSha256Id
xmlSecTransformEcdsaSha1Id
xmlSecTransformEcdsaSha224Id
xmlSecTransformEcdsaSha256Id
xmlSecTransformEcdsaSha384Id
xmlSecTransformEcdsaSha512Id
xmlSecTransformHmacMd5Id
xmlSecTransformHmacRipemd160Id
xmlSecTransformHmacSha1Id
xmlSecTransformHmacSha224Id
xmlSecTransformHmacSha256Id
xmlSecTransformHmacSha384Id
xmlSecTransformHmacSha512Id
xmlSecTransformMd5Id
xmlSecTransformRipemd160Id
xmlSecTransformRsaMd5Id
xmlSecTransformRsaRipemd160Id
xmlSecTransformRsaSha1Id
xmlSecTransformRsaSha224Id
xmlSecTransformRsaSha256Id
xmlSecTransformRsaSha384Id
xmlSecTransformRsaSha512Id
xmlSecTransformSha1Id
xmlSecTransformSha224Id
xmlSecTransformSha256Id
xmlSecTransformSha384Id
xmlSecTransformSha512Id
);

   return (first {$id eq $_ } @AllowedClass);

}

sub template4sign($$$$) {

   my $self=shift();
   my $doc=shift();
   my $algorithm=shift();
   my $id=shift();

   my $transform; #Transformation algorithm class
   my $digest;    #Digest algorithm class

   unless ($algorithm =~ /(\w{1,20})-(\w{1,20})/) {
      croak "Missformed algorithm $algorithm";
   }

   $transform='xmlSecTransform'.ucfirst(lc($1)).ucfirst(lc($2)).'Id';
   $digest='xmlSecTransform'.ucfirst(lc($2)).'Id';

   unless ($self->AllowedClass($transform)) {
      croak "Unknown transformation algorithm $1";
   }

   unless ($self->AllowedClass($digest)) {
	   croak "Unknown digest algorighm $2";
   }

   $transform = "Perl$transform";
   $digest="Perl$digest";
   $self->XMLCreateSignTemplate($doc,$self->$transform,$self->$digest,"#$id");

   return $doc;
   
}


1;
__END__

=head1 NAME

XML::LibXML::xmlsec - XML signing/encription using xmlsec library

=head1 SYNOPSIS

  use XML::LibXML::xmlsec;
  
  my $signer=XML::LibXML::xmlsec->new();
  $signer->loadpkey(PEM => 'jdoe.pem', secret => 'hush');
  $signer->template4sign($xmldoc,'rsa-sha1','MyDocument');
  $signer->signdoc($xmldoc);

  unless( $signer->verify($received_xml)) {
     die "This document was tampered";
  }

=head1 DESCRIPTION

XML::LibXML::xmlsec is a bind module for xmlsec, a C library aimed for XML digital signature and encryption
as described in W3C standards.


=head2 INSTALLATION

You must have a running xmlsec library, which in turns has several dependencies. 
There are xmlsec binaries built into many Linux distributions, as
well as binaries for Windows available.

=head1 METHODS

=head2 loadpkey

   $signer->loadpkey(PEM => 'me.pem', secret => 'mypassword');
   $signer->loadpkey(DER => 'me.pem', name => 'joe');
   $signer->loadpkey(PEM => $string_with_pem);

loadpkey will set the private key needed for digital signature. The key may be passed as a filename
value, or it might be the key itself as a string. A PEM=>val pair indicates PEM format, DER=>val indicates DER format
and PFX=>val indicates PKCS12 format.
An optional secret value will be used to decrypt the key. 
An optional name argument will be used to mention the private key in further methods.
Returns 0 on success. 

=head2 loadcert

   $signer->loadcert(PEM => 'me.crt', secret => 'hush')
   $signer->loadcert(PEM => 'joe.crt', name => 'joe')

loadcert will set the X509 certificate needed for verifying or digital signature. The value may be passed
in similar fashion as in loadpkey().

=head2 template4sign($doc,'rsa-sha256',$id)

Adds a signature template branch to the LibXML $doc for the signature
of the $id element. The second argument is a case insensitive string that identifies the algorithm combination
I<keying-digest> in order to setup the template. The algorithm must be one supported by
the xmlsec library and corresponds to the SignatureMethod definition.
Some of the known supported algorithms: RSA-SHA1, RSA-SHA224, RSA-SHA256,
RSA-SHA384, RSA-SHA512, DSA-SHA256, ECDSA-SHA25.
Returns the modified xml document

=head2 signdoc

   $signer->signdoc($xmldoc, %options);

signdoc will compute the digital signature and then add it as contents to the XML document.
The argument is expected to be a signature envelope as a well behaved L<LibXML::Document|https://metacpan.org/pod/distribution/XML-LibXML/lib/XML/LibXML/Document.pod>
already setup with the algorithm identifiers and the signature placeholder.

The options are as follows

=over 1

=item id => 'mydoc' indicates the id of the xml element subject of the signature

=item start => <libxml node> indicates a starting Signature o dsig:Signature of the signing process

=item id-attr => 'ID' indicates the name of the id attribute applied. Default lowercase 'id'

=item id-node => 'mytagname' indicates the tag name of the xml element subject of the signature

=back 

id-attr and id-node are provided as tweaks in order to be able to sign a DTD-less documents in the same way the option --id-attr works in xmlsec1 utility

=head2 $signer->verifydoc($xmldoc, %options);

verifydoc will verify an already signed xmldoc. Options are alike the signdoc method.
Will return 1 if verification is correct.

=head2 lastmsg

lastmsg will show the last error or warning message that might come out from
the xmlsec engine. Particularly the verifydoc will set this message so there's a
hint on the reason for a document to fail validation.

=head2 savekeys('store.xml',XML::LibXML::xmlsec::xmlSecKeyDataTypeAny)

This will dump the current contents of the previously loaded keys in the named file.
The second argument is a bitmask indicating which keys will be dumped. The file can
be used in the future with loadkeys
B<Please beware that any private key will be dumped unencrypted>
The options, as stated in xmlsec documentation are as follows:

=over 1

=item B<xmlSecKeyDataTypeUnknown> The key data type is unknown (same as xmlSecKeyDataTypeNone).

=item B<xmlSecKeyDataTypeNone> The key data type is unknown (same as xmlSecKeyDataTypeUnknown).

=item B<xmlSecKeyDataTypePublic> The key data contain a public key.

=item B<xmlSecKeyDataTypePrivate> The key data contain a private key.

=item B<xmlSecKeyDataTypeSymmetric> The key data contain a symmetric key.

=item B<xmlSecKeyDataTypeSession> The key data contain session key (one time key, n

=item B<xmlSecKeyDataTypePermanent> The key data contain permanent key (stored in keys manager).

=item B<xmlSecKeyDataTypeTrusted> The key data is trusted.

=item B<xmlSecKeyDataTypeAny> Any key data.

=back

=head2 loadkeys('store.xml')

This will restore a previously saved keys

=head1 LIMITATIONS AND TODO LIST

This module exposes only a subset of the xmlsec library features.
As it is

=over 4

=item *

Only signature and verification is available. Document encryption is on the TODO list

=item *

xmlsec can use several crypto engines. This perl module uses only the default
compiled-in crypto engine. Anyway, this is the reason why this module doesn't
interact with any Crypt or OpenSSL perl module.

=item *

xmlsec has a strong libxml2 binding. This module will accept XML::LibXML handles, but in turn
will do processing in the underlying xmlsec/libxml2 C libraries.

=back

=head1 SEE ALSO

See L<W3C XML signature definition|https://www.w3.org/TR/xmldsig-core/>.
See L<W3C XML encryption definition|https://www.w3.org/TR/xmlenc-core/>.
The original xmlsec library has a webpage at L<https://www.aleksey.com/xmlsec/>

=head1 AUTHOR

Erich Strelow, E<lt>hstrelo@puc.clE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
