package VOMS::Lite::CertKeyHelper;

use 5.004;
use strict;
use VOMS::Lite::ASN1Helper qw(ASN1Index ASN1Unwrap ASN1Wrap Hex ASN1OIDtoOID);
use VOMS::Lite::RSAHelper qw(rsasign rsaverify);
use VOMS::Lite::PEMHelper qw(readCert);
use VOMS::Lite::X509;
use Digest::MD5 qw(md5);

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
%EXPORT_TAGS = ( );
@EXPORT_OK = qw(buildchain digestSign OIDtoDNattrib DNattribToOID);
@EXPORT = ( );
$VERSION = '0.20';
##################################################

# Define some common OIDs used in Distunguished names NB we're using UID and Email not UserID and emailAddress
my %DNOIDs=( '2.5.4.49'                   => 'DN',
             '0.9.2342.19200300.100.1.1'  => 'UID',
             '0.9.2342.19200300.100.1.25' => 'DC',
             '1.2.840.113549.1.9.1'       => 'Email',
             '2.5.4.3'                    => 'CN',
             '2.5.4.4'                    => 'SN',
             '2.5.4.5'                    => 'serialNumber',
             '2.5.4.6'                    => 'C',
             '2.5.4.7'                    => 'L',
             '2.5.4.8'                    => 'ST',
             '2.5.4.9'                    => 'street',
             '2.5.4.12'                   => 'title',
             '2.5.4.16'                   => 'postalAddress',
             '2.5.4.17'                   => 'postalCode',
             '2.5.4.18'                   => 'postOfficeBox',
             '2.5.4.26'                   => 'registeredAddress',
             '2.5.4.11'                   => 'OU',
             '2.5.4.41'                   => 'name',
             '2.5.4.10'                   => 'O',
             '2.5.4.42'                   => 'givenName',
             '2.5.4.43'                   => 'initials',
             '2.5.6.3'                    => 'locality',
             '2.5.6.4'                    => 'organization');

my %DNAttribs=( reverse %DNOIDs,
                commonName             => '2.5.4.3',
                serialNumber           => '2.5.4.4',
                countryName            => '2.5.4.6',
                localityName           => '2.5.4.7',
                stateOrProvinceName    => '2.5.4.8',
                organizationName       => '2.5.4.10',
                organizationalUnitName => '2.5.4.11',
                emailAddress           => '1.2.840.113549.1.9.1',
                UserID                 => '0.9.2342.19200300.100.1.1',
                domainComponent        => '0.9.2342.19200300.100.1.25'
		);

sub OIDtoDNattrib {
  return (defined $DNOIDs{$_[0]})?$DNOIDs{$_[0]}:$_[0];
}

sub DNattribToOID {
  return (defined $DNAttribs{$_[0]})?$DNAttribs{$_[0]}:undef;
}

##################################################

sub verifychain {
  my ($lastExp,$lastMod,$lastCAPurpose,$lastKeyCertSign,$lastkeyUsageDigitalSignature,$EECDN,$EECIDN,$EEC);
  my @Self;
  my @Time;
  my @LifeTime;
  my @Signed; 
  my @SignerPurposeCA; 
  my @SignerCertSignPurpose; 
  my @PathLen; 
  my @GSIType; 
  my @ProxyPathLen; 
  my $now=time();

# Loop over certificate starting at 'root-most'
  foreach ( reverse @_ ) {
    my %CI = %{ VOMS::Lite::X509::Examine( $_ , { SubjectDN=>"", 
                                                  IssuerDN=>"", 
                                                  Start=>"", 
                                                  End=>"", 
                                                  SignatureType=>"", 
                                                  SignatureValue=>"", 
                                                  X509TBSCert=>"", 
                                                  keyUsage=>"", 
                                                  basicConstraints=>"", 
                                                  KeypublicExponent=>"", 
                                                  Keymodulus=>"",
                                                  authorityKeyIdentifier=>"", 
                                                  subjectKeyIdentifier=>"",  
                                                  ProxyInfo=>"" 
                                                }) };

# Check if selfsigned, if first in chain set 'last' values to these values
    push @Self,0;
    if ( $CI{IssuerDN} eq $CI{SubjectDN} ) {
      if ( ! defined $CI{authorityKeyIdentifierSkid} || $CI{subjectKeyIdentifier} eq $CI{authorityKeyIdentifierSkid} ) {
        $Self[-1]=1;
        if ( ! defined $lastMod ) {
          $lastExp                      = Hex($CI{KeypublicExponent});
          $lastMod                      = Hex($CI{Keymodulus});
          $lastCAPurpose                = $CI{basicConstraintsCA};
          $lastKeyCertSign              = $CI{keyUsageKeyCertSign};
          $lastkeyUsageDigitalSignature = $CI{keyUsageDigitalSignature};
    } } }

# Check Validity of Time, signature, Issuer's purpose and key usage, and path length
    push @Time, ( $CI{Start} < $now && $CI{End} > $now ) ? 1:0;
    push @PathLen, ( defined $CI{basicConstraintsPathLen} && $CI{basicConstraintsPathLen} < ($#_-$#PathLen) ) ? 0:1; 
    push @Signed, verifySignature($CI{SignatureType},Hex($CI{SignatureValue}),$CI{X509TBSCert},$lastExp,$lastMod);
    push @SignerPurposeCA, $lastCAPurpose;
    push @SignerCertSignPurpose, $lastKeyCertSign;
#   TODO Check CRL:  1 find CRL  2 In Date  3 CRL Signed 4 CA has keyUsageCRLSign 5 Cert not in List 

# Check GSIness
    if ( ! $SignerPurposeCA[-1] && ! $SignerCertSignPurpose[-1] && $lastkeyUsageDigitalSignature) {
      if    ( $CI{SubjectDN} eq "$CI{IssuerDN}/CN=proxy" ) { 
        if    ( $CI{IssuerDN} =~ /\/CN=limited proxy$/ )           { push @GSIType,"Bad Legacy proxy: issuer was limited" }
        else                                                       { push @GSIType,"Legacy Proxy" } 
      }
      elsif ( $CI{SubjectDN} eq "$CI{IssuerDN}/CN=limited proxy" ) { push @GSIType,"Limited Proxy"; }
      elsif ( $CI{ProxyInfo} eq 'RFC' || $CI{ProxyInfo} eq 'Pre-RFC' ) {
        if    ( $CI{SubjectDN} !~ /^$CI{IssuerDN}\/CN=[0-9]+$/ )   { push @GSIType,"Bad RFC proxy: issuer name mismatch" }
        elsif ( $CI{IssuerDN} =~ /\/CN=(?:limited )?proxy$/ )      { push @GSIType,"Bad legacy proxy: issuer was legacy" }
        else                                                       { push @GSIType,"$CI{ProxyInfo} Proxy"; } 
      }
      else                                                         { push @GSIType,"Bad proxy"; }
    }
    else { 
      if ( $CI{basicConstraintsCA} || $CI{keyUsageKeyCertSign} )   { push @GSIType,"CA" }
      else                                                         { push @GSIType, "EEC";
        ($EECDN,$EECIDN,$EEC) = ($CI{SubjectDN},$CI{IssuerDN},$_);
      }
    }

# GSI PathLen
    push @ProxyPathLen,(defined $CI{"ProxyPathlen$CI{ProxyInfo}"} && $CI{"ProxyPathlen$CI{ProxyInfo}"}<($#_-$#ProxyPathLen))?0:1;

# Populate remaining times array
    push @LifeTime, ( $CI{End} - $now );

# Remember relevant parts of this certificate as issuer for next
    $lastExp                      = Hex($CI{KeypublicExponent});
    $lastMod                      = Hex($CI{Keymodulus});
    $lastCAPurpose                = $CI{basicConstraintsCA};
    $lastKeyCertSign              = $CI{keyUsageKeyCertSign};
    $lastkeyUsageDigitalSignature = $CI{keyUsageDigitalSignature};
  }

  my $i=0;
  my @returnErrors;
  while ( defined $Time[$i] ) {
    my @errors=();
    if ( $i > 0 && $GSIType[$i] =~ /^Bad/ )       { push @errors, $GSIType[$i]; }
    if ( ! $Time[$i] )                            { push @errors, "Time error in certificate $i"; }
    if ( ! $Signed[$i] && ( $i!=0 || $Self[$i] )) { push @errors, "Bad signature on certificate $i"; }
    if ( $i!=0 && $Self[$i] )                     { push @errors, "Self signed certificate in at $i the chain"; }
    if ( $GSIType[$i] !~ /^(?:Lega[sc]y|Limited|RFC|Pre-RFC) Proxy$/ && ( $i!=0 || $Self[$i] ) ) {
      if ( ! $SignerPurposeCA[$i] )               { push @errors, "Signer of certificate $i is not a CA"; }
      if ( ! $SignerCertSignPurpose[$i] )         { push @errors, "Signer of certificate $i may not sign certificates"; }
    }
    if ( ! $PathLen[$i] )                         { push @errors, "Path Length exceeded at certificate $i"; }
    if ( ! $ProxyPathLen[$i] )                    { push @errors, "Proxy Path Length exceeded at certificate $i"; }
    push @returnErrors,\@errors;
    $i++;
  }
  return ( \@returnErrors, \@GSIType, \@LifeTime, $EECDN, $EECIDN, $EEC );
}

##################################################

sub buildchain {
  my $inref   = shift;
  my %in      = %{$inref};

  my @CAdirs  = (defined $in{'trustedCAdirs'})? @{$in{'trustedCAdirs'}}:();
  my @certs   = (defined $in{'suppliedcerts'})? @{$in{'suppliedcerts'}}:();
  my @CAcerts = (defined $in{'trustedCAs'})?    @{$in{'trustedCAs'}}:();

  my %cert; my %hash; my %ihash; my %skid; my %akid; my %dn; my %idn; my %dir; my %trust;
  my $CertHashTemplate={authorityKeyIdentifier=>"", subjectKeyIdentifier=>"", keyUsage=>"", basicConstraints=>"",IHash=>"",Hash=>"",SubjectDN=>"",IssuerDN=>""};

# Load Leaf certificate information
  my @returnCerts = (shift @certs); # First one is treated as the leaf certificate/gsi-certificate 
  my $CertInfoRef = VOMS::Lite::X509::Examine( $returnCerts[0] ,$CertHashTemplate);
  my %CERTINFO    = %$CertInfoRef;
  my @IHash       = ($CERTINFO{IHash});
  my @Hash        = ($CERTINFO{Hash});
  my @SKID        = ($CERTINFO{subjectKeyIdentifier});
  my @AKID        = ($CERTINFO{authorityKeyIdentifierSkid});
  my @DNs         = ($CERTINFO{SubjectDN});
  my @IDNs        = ($CERTINFO{IssuerDN});
  my @Trust       = (0);

#Make place holder for CA certs which reside in supplied directories (only load them if needed) 
  my @cas;
  foreach my $dir (reverse @CAdirs) {  # First directory takes presidence
    opendir(GRIDSECURITYDIR,$dir);
    push @cas, grep(/\.[0-9]+$/, readdir(GRIDSECURITYDIR));
    closedir(GRIDSECURITYDIR);
    foreach (@cas) { 
      $hash{$_}="$_"; 
      $cert{$_}=""; 
      $dir{$_}=$dir;
    }
  }

#Load locally supplied CAcert info and peer supplied CAcert info
  my $remainingtrusted=$#CAcerts;
  foreach (@CAcerts,@certs) {
    my $CertInfoRef=VOMS::Lite::X509::Examine($_,$CertHashTemplate);
    my %CERTINFO=%$CertInfoRef;
    my $index=0;
    until ( ! defined $hash{"$CERTINFO{Hash}.$index"} ) { $index++; }
    $cert{"$CERTINFO{Hash}.$index"}  = $_;
    $hash{"$CERTINFO{Hash}.$index"}  = $CERTINFO{Hash};
    $ihash{"$CERTINFO{Hash}.$index"} = $CERTINFO{IHash};
    $skid{"$CERTINFO{Hash}.$index"}  = $CERTINFO{subjectKeyIdentifier};
    $akid{"$CERTINFO{Hash}.$index"}  = $CERTINFO{authorityKeyIdentifierSkid};
    $dn{"$CERTINFO{Hash}.$index"}    = $CERTINFO{SubjectDN};
    $idn{"$CERTINFO{Hash}.$index"}   = $CERTINFO{IssuerDN};
    $trust{"$CERTINFO{Hash}.$index"} = ( $remainingtrusted > -1 ) ? 1:0; #trust only locally supplied certs
    $remainingtrusted--;
  }

#Loop round all certificate authorities until the chain is constructed or there are no found issuers.
  my $found;
  my $self=0;
  for(;;) {
    $found="no";
    my @a;
    foreach (keys(%cert)) { if ($_ =~ /^$IHash[-1].[0-9]+$/ ) { push @a, $_;} }
    my @b=sort(@a);
    foreach my $file ( @b ) {
      if ( $cert{$file} eq "" && defined $dir{$file} ) { # Load in CA certificate as required
        my $certder     = readCert("$dir{$file}/$file");
        my $CertInfoRef = VOMS::Lite::X509::Examine($certder,$CertHashTemplate);
        my %CERTINFO    = %$CertInfoRef;
        $cert{$file}    = $certder;
        $hash{$file}    = $CERTINFO{Hash};
        $ihash{$file}   = $CERTINFO{IHash};
        $skid{$file}    = $CERTINFO{subjectKeyIdentifier};
        $akid{$file}    = $CERTINFO{authorityKeyIdentifierSkid};
        $dn{$file}      = $CERTINFO{SubjectDN};
        $idn{$file}     = $CERTINFO{IssuerDN};
        $trust{$file}   = 1;
      }

      if($IDNs[-1] eq $dn{$file} && ( ! defined $AKID[-1] || $AKID[-1] eq $skid{$file} ) ) { #Issuer names match and Key ID's match 
        $found="yes";
        if ( $DNs[-1] eq $IDNs[-1] && ( ! defined $AKID[-1] || $SKID[-1] eq $AKID[-1] )) { #Check last cert not self-signed
          $self=1; 
          $Trust[-1]=1; 
          last; 
        }
        else {
          push @returnCerts, $cert{$file};
          push @IHash,       $ihash{$file};
          push @Hash,        $hash{$file};
          push @SKID,        $skid{$file};
          push @AKID,        $akid{$file};
          push @DNs,         $dn{$file};
          push @IDNs,        $idn{$file};
          push @Trust,       $trust{$file};
          last;
        }
      }
    }
    # Stop looping if no signer found or certificate is self signed
    last if ( $found eq "no" );
    if ( $DNs[-1] eq $IDNs[-1] && ( !defined $AKID[-1] || $SKID[-1] eq $AKID[-1] )) { $self=1; last; }
  }
  my @verify   = verifychain(@returnCerts);
  my @Errors   = reverse @{ $verify[0] };
  my @GSI      = reverse @{ $verify[1] };
  my @LifeTime = reverse @{ $verify[2] };
  my $EECDN    = $verify[3];
  my $EECIDN   = $verify[4];
  my $EEC      = $verify[5];

  return { Certs                        => \@returnCerts,
           IssuerHashes                 => \@IHash,
           SubjectHashes                => \@Hash,
           SubjectKeyIdentifiers        => \@SKID,
           AuthorityKeyIdentifiersSKIDs => \@AKID,
           DistinguishedNames           => \@DNs,
           IssuerDistinguishedNames     => \@IDNs,
           TrustedCA                    => \@Trust,
           SelfSignedInChain            => $self,
           GSIType                      => \@GSI,
           EndEntityDN                  => $EECDN,
           EndEntityIssuerDN            => $EECIDN,
           EndEntityCert                => $EEC,
           Lifetimes                    => \@LifeTime,
           Errors                       => \@Errors
          }
}

################################################################

# Need type of digestType, BinaryData, HexKey, HexModulus, 
sub digestTBS {
  my ($type,$Data) = @_;

  if ( $type eq "md5WithRSA" ) { # 128 bit digest
    if ( eval "require Digest::MD5" ) {
      # 1.2.840.113549.2.5 for use with 1.840.113549.1.1.4 for RSA signatures
      return ASN1Wrap("30","300c06082a864886f70d02050500".ASN1Wrap("04",Digest::MD5::md5_hex($Data))); 
    }
  }
  elsif ( $type eq "sha1WithRSA" ) { # 160-bit
    if ( eval "require Digest::SHA1" ) {
      # 1.3.14.3.2.26 for use with 1.840.113549.1.1.5 for RSA signatures
      return ASN1Wrap("30","300906052b0e03021a0500".ASN1Wrap("04",Digest::SHA1::sha1_hex($Data))); 
    }
  }
  elsif ( $type eq "md2WithRSA" ) { # 128 bit
    if ( eval "require Digest::MD2" ) {
      # 1.840.113549.2.2 for use with 1.840.113549.1.1.2 for RSA signatures
      return ASN1Wrap("30","300c06082a864886f70d02020500".ASN1Wrap("04",Digest::MD2::md2_hex($Data))); 
    }
  }
#  elsif ( $type eq "md4WithRSA" ) { #128 bit
#    if ( eval "require Digest::MD4" ) {
#      # 1.840.113549.2.4 for use with  1.840.113549.1.1.3 for RSA signatures
#      return ASN1Wrap("30","300c06082a864886f70d02040500".ASN1Wrap("04",Digest::MD4::md4_hex($Data))); 
#    }
#  }
  return undef;
}

################################################################
#digestSign("md5WithRSA",$Data,$chex,$nhex);
sub digestSign {
  my ($type,$Data,$chex,$nhex) = @_;
  my $digestTBS=digestTBS($type,$Data);

  if ( defined $digestTBS ) { return rsasign($digestTBS,$chex,$nhex); }
  return "";
}

################################################################

sub verifySignature {
  my ($digestType,$SignedInfo,$TBS,$chex,$nhex)=@_;
  return 1 if ( digestTBS($digestType,$TBS) eq rsaverify($SignedInfo,$chex,$nhex) );
  return 0;
}

################################################################

1;
__END__

=head1 NAME

VOMS::Lite::CertKeyHelper - Perl extension for parsing DER encoded X509 certificates for the VOMS::Lite module.

=head1 SYNOPSIS

  use VOMS::Lite::CertKeyHelper qw (x509rsasign buildchain OIDtoDNattrib DNattribToOID);

  # Call x509rsasign with three hex encoded arguments: Data, Exponent and Modulus.
  $RSAhex=x509rsasign($Dhex,$chex,$nhex);

  # Call buildchain to construct the chain of a certificate given any 
  # unverified supplied certs, trusted cert and directories containing 
  # certicates stored by hash name.
  # The returned hash contains references to arrays with DER encoded 
  # certificates and other information see DESCRIPTION.  
  my %Chain = %{ buildchain(trustedCAdirs => \@CAdirs, 
                            suppliedcerts => \@certs, 
                               trustedCAs => \@CAcerts }) };

  # Convert OID string to DN Attribute e.g. '1.2.840.113549.1.9.1' => 'Email' (yes we do use Email here!)
  my $Attribkey=OIDtoDNattrib('1.2.840.113549.1.9.1');

  # Convert DN Attribute e.g. 'Email' to it's OID '1.2.840.113549.1.9.1' 
  my $Attribkey=DNattribToOID('1.2.840.113549.1.9.1'); #Note the Case change DNattribToOID not DNattribtoOID!

=head1 DESCRIPTION

VOMS::Lite::CertKeyHelper is primarily for internal use.

buildchain:- Takes an array of directories conatining "hash.[0-9]+" encoded Certificates
             an array of a supplied certificate chain  (1st ELEMENT ASSUMED TO BE LAST IN CHAIN),
             and an array of DER encoded CA certificates.
             Returns a hash of array references and scalars:
             The Arrays are ordered such that the first element is the leaf the next is its 
             signer and so on to the last which will be the root certificate (if found).
             The return hash contains the following keys:
  Certs                        -- Reference to Array (chain) of certificates. 
  IssuerHashes                 -- Reference to Array of OpenSSL style Name hash of Issuer
  SubjectHashes                -- Reference to Array of OpenSSL style Name Hash
  SubjectKeyIdentifiers        -- Reference to Array of Subject key identifiers
  AuthorityKeyIdentifiersSKIDs -- Reference to Array of Authority's Subject key identifiers
  DistinguishedNames           -- Reference to Array: certificate N's Subject DN '/' seperated
  IssuerDistinguishedNames     -- Reference to Array: certificate N's Issuer DN '/' seperated
  TrustedCA                    -- Reference to Array of whether certificate N is trusted i.e. there's a local copy
  SelfSignedInChain            -- Scalar: True if there is a selfsigned certificate in the chain. 
  GSIType                      -- Reference to Array of strings containing type of certificate certificate N is.
  EndEntityDN                  -- Scalar: DN of End entity certificate '/' seperated
  EndEntityIssuerDN            -- Scalar: DN of EEC's Issuer '/' seperated
  EndEntityCert                -- Scalar: End Entitie's DER encoded certificate 
  Lifetimes                    -- Reference to Array of lifetimes
  Errors                       -- Reference to Array errors

  buildchain does do some rudementry certificate validation but 
  currently does not handle CRLs

x509rsasign:- return the ASN1 encoded signature of an MD5 string 
passed as first argument (as per RFC2313)

OIDtoDNattrib :-  convert an OID to a DN string representation attribute type.
Where OIDtoDNattrib is handed an OID it does not recognise it will return the OID.  
OIDtoDNattrib knows about: DN, UID, DC, Email, CN, SN, serialNumber, C, L, ST, 
street, title, postalAddress, postalCode, postOfficeBox, registeredAddress, OU, 
name, O, givenName, initials, locality, organization

DNattribToOID:- convert a DN string representation attribute type to an OID. 
Where DNattribToOID does not recognise an Attribute it will return undef.
DNattribToOID knows the same attributes as OIDtoDNattrib and will also accept: 
commonName, serialNumber, countryName, localityName, stateOrProvinceName, 
organizationName, organizationalUnitName, emailAddress, UserID, and domainComponent.

=head3 Notes on DNs

The slash representation of a DN is a really bad way to express the 
contents of a certificate issuer or subject field.  This 
implementation recognises only a handful of OIDs and, especially, 
translates 0.9.2342.19200300.100.1.1 into UID and 
1.2.840.113549.1.9.1 into Email.

=head2 EXPORT

None by default.

The following functions can be imported:
buildchain digestSign OIDtoDNattrib DNattribToOID.

=head1 TO DO

Add CRL checking functionality to the verifychain internal function called by buildchain. 

=head1 SEE ALSO

RFC3280

This module was originally designed for the SHEBANGS project at 
The University of Manchester.

http://www.mc.manchester.ac.uk/projects/shebangs/
now http://www.rcs.manchester.ac.uk/research/shebangs/

Mailing list, shebangs@listserv.manchester.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
