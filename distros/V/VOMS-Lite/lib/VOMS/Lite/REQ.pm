package VOMS::Lite::REQ;

use 5.004;
use strict;
use VOMS::Lite::CertKeyHelper qw(OIDtoDNattrib digestSign DNattribToOID);
use VOMS::Lite::ASN1Helper qw(ASN1OIDtoOID ASN1Index ASN1Wrap ASN1Unwrap ASN1UnwrapHex DecToHex Hex ASN1BitStr OIDtoASN1OID);
use VOMS::Lite::X509;
use VOMS::Lite::KEY;
use Digest::SHA1 qw(sha1_hex);
use Digest::MD5 qw(md5);
use VOMS::Lite::RSAKey;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

$VERSION = '0.20';

sub Examine {
  my ($decoded,$dataref)=@_;
  my %Values=%$dataref;
  my @ASN1Index=ASN1Index($decoded);

  return ( {Errors=> [ "Unable to parse certificate request" ]} ) if (@ASN1Index==0);

  my ($index,$ignoreuntil)=(0,0);
  my ($REQInfo,$REQversion,$REQsubject,$REQsubjectPublicKeyInfo,$REQattributes,$REQSignatureAlgorithm,$REQSignatureValue);

# Drill down into the certificate
  shift @ASN1Index; # skip the wrapping of the certificate sequence
  my $REQInfoRef=shift @ASN1Index; #CertificateTBS Sequence
  if (defined $Values{REQInfo}) {
    my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @$REQInfoRef;
    $Values{REQInfo}=substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));
  }

# Extract the main components of the certificate
  foreach (@ASN1Index) {
    my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @$_;
    if ( $HEADSTART < $ignoreuntil ) { next; }
    else {
      if    ($index==0 && $TAG==2)  {$REQversion              = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==1 && $TAG==16) {$REQsubject              = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==2 && $TAG==16) {$REQsubjectPublicKeyInfo = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==3 && $CLASS==2 && $TAG==0) {$REQattributes  = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==3 && $TAG==16) {$REQSignatureAlgorithm   = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==4 && $TAG==3) {$REQSignatureValue        = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      $ignoreuntil=$HEADSTART+$HEADLEN+$CHUNKLEN;
    }
}
  if ($index != 4) {return undef;} #Failed to read certificate request

#Standard
  if (defined $Values{REQversion})              {$Values{REQversion}=$REQversion;}
  if (defined $Values{REQsubject})              {$Values{REQsubject}=$REQsubject;}
  if (defined $Values{REQsubjectPublicKeyInfo}) {$Values{REQsubjectPublicKeyInfo}=$REQsubjectPublicKeyInfo;}
  if (defined $Values{REQattributes})           {$Values{REQattributes}=$REQattributes;}
  if (defined $Values{REQSignatureAlgorithm})   {$Values{REQSignatureAlgorithm}=$REQSignatureAlgorithm;}
  if (defined $Values{REQSignatureValue})       {$Values{REQSignatureValue}=$REQSignatureValue;}

##################
# Helpers  -- Deeper parsing of certificate

# The String Repersentation of the subject and issuer DNs
  if (defined $Values{SubjectDN}) {
    my @ASN1SubjectDNIndex=ASN1Index($REQsubject);
    shift @ASN1SubjectDNIndex;
    $Values{SubjectDN}="";
    while (@ASN1SubjectDNIndex) {
      my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN)=(0,0,0,0,0);
      until ($TAG == 6 ) { ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ASN1SubjectDNIndex}; }
      my $OID=substr($REQsubject,($HEADSTART+$HEADLEN),$CHUNKLEN);
      ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ASN1SubjectDNIndex};
      my $Value=substr($REQsubject,($HEADSTART+$HEADLEN),$CHUNKLEN);
      $Values{SubjectDN}.="/".OIDtoDNattrib(ASN1OIDtoOID($OID))."=$Value";
    }
  }

# Public key and Modulus
  if ( defined $Values{KeypublicExponent} || defined $Values{Keymodulus} ) {
    my ($OID,$modexpbitstr);
    my @KeyIndex=ASN1Index($REQsubjectPublicKeyInfo);
    foreach (@KeyIndex) {
      my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @$_;
      if ( ! $CONSTRUCTED ) {
        $OID=Hex(substr($REQsubjectPublicKeyInfo,($HEADSTART+$HEADLEN),$CHUNKLEN)) if ( $TAG == 6 );
        $modexpbitstr=substr($REQsubjectPublicKeyInfo,($HEADSTART+$HEADLEN),$CHUNKLEN) if ( $TAG == 3 );
      }
    }
    if ( $OID eq "2a864886f70d010101" ) {
      $modexpbitstr=~ s/.//; # BS always encoding 8 bit bytes
      my @KeyIndex2=ASN1Index($modexpbitstr);
      shift @KeyIndex2;
      my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @KeyIndex2};
      $Values{Keymodulus}=substr($modexpbitstr,($HEADSTART+$HEADLEN),$CHUNKLEN);
      ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @KeyIndex2};
      $Values{KeypublicExponent}=substr($modexpbitstr,($HEADSTART+$HEADLEN),$CHUNKLEN);
    }
  }

# Signature Value
  if (defined $Values{SignatureValue} || defined $Values{SignatureType}) {
    $Values{SignatureValue}=substr(ASN1Unwrap($REQSignatureValue),1);
    my $HexREQsignature=Hex($REQSignatureAlgorithm);
    if    ( $HexREQsignature eq "300d06092a864886f70d0101040500" ) { $Values{SignatureType}="md5WithRSA"; }
    elsif ( $HexREQsignature eq "300d06092a864886f70d0101050500" ) { $Values{SignatureType}="sha1WithRSA"; }
    elsif ( $HexREQsignature eq "300d06092a864886f70d0101030500" ) { $Values{SignatureType}="md4WithRSA"; }
    elsif ( $HexREQsignature eq "300d06092a864886f70d0101020500" ) { $Values{SignatureType}="md2WithRSA"; }
    else  { $Values{SignatureType}="unrecognised"; }
  }
  return (\%Values);
}

####################################################


sub Create {

# Load in Context
  my %context = %{ shift() };

# Create error and warning arrays
  my @Errors;
  my @Warnings;

# Get request time;
  my $now=time();

# Check for required input values
  if ( ! defined $context{'DN'} && ! defined $context{'Cert'} )      { push @Errors,   "REQ: Distinguished Name not supplied"; }
  if ( defined $context{'DN'} && defined $context{'Cert'} )          { push @Errors,   "REQ: Two methods specified for DN"; }

# Bail if there isn't enough information
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

# Check input values
  if ( defined $context{'DN'} && ref($context{'DN'}) ne "ARRAY" )    { push @Errors, "REQ: DN Must be a reference to an array of distinguished name component strings."; }
  if ( defined $context{'Bits'} && $context{'Bits'} !~ /^(512|1024|2048|4096)$/ ) { push @Errors, "REQ: Key size can only be 512, 1024, 2048 or 4096."; }  
  elsif ( ! defined $context{'Bits'} ) { $context{'Bits'} = 1024; }
  my $Verbosity=((defined $context{'Quiet'})?0:1);

# Bail if inputs are not the right format
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

# Load input data into local variables
  my ($CertInfoRef,$KeyInfoRef)=(undef,undef);
  my %CI;
  my %KI;
  if ( defined $context{'Cert'} ) {
    $CertInfoRef = (($context{'Cert'} =~ /^(\060.+)$/s) ? VOMS::Lite::X509::Examine($&, {X509subject=>"", SubjectDN=>""}) : undef);
    if ( defined $CertInfoRef )  { %CI=%$CertInfoRef; } else { push @Errors, "REQ: Unable to parse CA certificate."; }
  }
  if ( defined $context{'Key'} ) {
    $KeyInfoRef  = (($context{'Key'}  =~ /^(\060.+)$/s) ?  VOMS::Lite::KEY::Examine($&, {Keymodulus=>"", KeyprivateExponent=>"", KeypublicExponent=>""}) : undef);
    if ( defined $KeyInfoRef )   { %KI=%$KeyInfoRef;  } else { push @Errors, "REQ: Unable to parse CA key."; }    
  }

# Bail if there is a certificate Parse error
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

# Check for unknown options
  foreach (keys %context) { if ( ! /^(Quiet|DN|Bits|Cert|Key|subjectAltName)$/ ) {push @Errors, "REQ: $_ is an invalid option.";}}

# Bail if any recognised options are invalid
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

###################################################################
# Do not edit below these lines (unless there's a bug of course!) #
###################################################################

  my $host=0;

# Check and parse the DN array referenced
  if ( defined $context{'DN'} ) {
    $CI{'X509subject'}="";
    foreach (@{ $context{'DN'} }) { 
      my ($attrib,$value)=split(/=/,$_,2); # Splits attribute and value
      my $OID = DNattribToOID($attrib);    # Convert Attribute to dot representation e.g. CN -> 2.5.4.3
      if ( defined $OID ) {
        my $STRtype;
        if    ( $value =~ /^[a-zA-Z0-9 \x22()+,.\/:?-]*$/ )                              { $STRtype="13"; } # Printable String
        elsif ( $value =~ /^[\x00\x07-\x0f\x11-\x14\x18-\x1b\x20-\x23\x25-\x7d\x7f]*$/ ) { $STRtype="16"; } #IA5 String
        else { push @Errors, "REQ: Can't find an apropriate encoding for $attrib+$value."; }
        if ( defined $STRtype ) { $CI{'X509subject'} .= ASN1Wrap("31",ASN1Wrap("30",ASN1Wrap("06",Hex(OIDtoASN1OID($OID))).ASN1Wrap($STRtype,Hex($value)))) }; 
        if ( $OID eq '2.5.4.3' && $value =~ /^[a-zA-Z0-9]+\.[a-zA-Z0-9]+$/ ) { $host = 1;} # detect that this is a host name for later use
      }
      else { push @Errors, "REQ: unknown Attribute: $attrib"; }
    }
    if ( $CI{'X509subject'} eq "" ) { push @Errors, "REQ: No Attributes in Distunguished Name"; } ;
    $CI{'X509subject'}=ASN1Wrap("30",$CI{'X509subject'}); # The DN in an apropriate X.509 ASN1 structure.
    $CI{'X509subject'}=~ s/(..)/pack('C',hex($&))/ge;
  }
  elsif ( ! defined $CI{'X509subject'} ) { push @Errors, "REQ: Unable to obtain Subject of certificate supplied"; }
  else { if ( $CI{'SubjectDN'} =~ /\/CN=[a-zA-Z0-9]+\.[a-zA-Z0-9]+/ ) {$host = 1;} } # detect that this is a host name for later use

# Bail if DN is bad
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

###############################
#OK Let's create an REQ Cred!#
###############################

  my $Keymodulus;
  my $KeyprivateExponent;
  my $KeypublicExponent;
  my $Privatekey;
  if ( ! defined $context{'Key'} ) { # Need to generate a key pair

# Generate Key Pair
#    my $keyref = VOMS::Lite::Key::GenRSAKey( { Bits => 512, Verbose => (defined $context{'Quiet'})?undef:"y" } );
    my $keyref = VOMS::Lite::RSAKey::Create( { Bits => $context{'Bits'}, Verbose => (defined $context{'Quiet'})?undef:"y" } );
    if ( ! defined $keyref ) { return { Errors => [ "REQ: Key Generation Failure" ] } ; }
    my %key = %{ $keyref }; 
    if ( defined $key{'Error'} ) { return { Errors => [ "REQ: Error in Key Generation ".$key{'Error'} ] } ; }

###Private Key#####################################################

# Keyversion Keymodulus KeypublicExponent KeyprivateExponent
# Keyprime1 Keyprime2 Keyexponent1 Keyexponent2 Keycoefficient

    my $Keyversion =         "020100";
    $Keymodulus =            ASN1Wrap("02",DecToHex($key{Modulus}));
    $KeypublicExponent =     ASN1Wrap("02",DecToHex($key{PublicExponent}));
    $KeyprivateExponent =    ASN1Wrap("02",DecToHex($key{PrivateExponent}));
    my $Keyprime1 =          ASN1Wrap("02",DecToHex($key{Prime1}));
    my $Keyprime2 =          ASN1Wrap("02",DecToHex($key{Prime2}));
    my $Keyexponent1 =       ASN1Wrap("02",DecToHex($key{Exponent1}));
    my $Keyexponent2 =       ASN1Wrap("02",DecToHex($key{Exponent2}));
    my $Keycoefficient =     ASN1Wrap("02",DecToHex($key{Iqmp}));

    $Privatekey=ASN1Wrap("30",$Keyversion.$Keymodulus.$KeypublicExponent.$KeyprivateExponent.
                              $Keyprime1.$Keyprime2.$Keyexponent1.$Keyexponent2.$Keycoefficient);

    $KI{Keymodulus}          = DecToHex(${ $keyref }{Modulus});
    $KI{KeyprivateExponent}  = DecToHex(${ $keyref }{PrivateExponent});
    $KI{Keymodulus}         =~ s/(..)/pack("C",hex($&))/ge;
    $KI{KeyprivateExponent} =~ s/(..)/pack("C",hex($&))/ge;
  }
  else {
#foreach (keys %KI) { print "$_ -> ".Hex($KI{$_})."\n"; }
#    $Keymodulus         = ASN1Wrap("02",ASN1Unwrap($KI{Keymodulus}));
#    $KeypublicExponent  = ASN1Wrap("02",ASN1Unwrap($KI{KeypublicExponent}));
#    $KeyprivateExponent = ASN1Wrap("02",ASN1Unwrap($KI{KeyprivateExponent}));
    $Keymodulus         = ASN1Wrap("02",Hex($KI{Keymodulus}));
    $KeypublicExponent  = ASN1Wrap("02",Hex($KI{KeypublicExponent}));
    $KeyprivateExponent = ASN1Wrap("02",Hex($KI{KeyprivateExponent}));
    $Privatekey         = $context{'Key'};
  }

###Request Bits######################################################
# TBSRequest:
#  REQversion REQsubjext REQsubjectPublicKeyInfo REQext

#### Certificate Version #### (x509 v3)
  my $REQversion = "020100";

#### Subject ####
  my $REQsubject=Hex($CI{'X509subject'});

#### Public Key (RSA) ####
  my $PubKeyChunk=ASN1Wrap("30",$Keymodulus.$KeypublicExponent);
  my $REQsubjectPublicKeyInfo=ASN1Wrap("30",ASN1Wrap("30","06092a864886f70d0101010500").ASN1Wrap("03",ASN1BitStr($PubKeyChunk)));

#### Something Else ####
  my $REQExt="a000";

#  1.2.840.113549.1.9.14 Request extension
# a0 [ SEQ [ OID [ 1.2.840.113549.1.9.14 ] SET [ SEQ [ SEQ [ OID [ 2.5.29.17 ] $SubjectAltName ] ] ] ] ]
# Check and parse the SubjectAltName array referenced
  my $SubjectAltNameExt="";
  if ( defined $context{'subjectAltName'} ) {
    my $SubjectAltName="";
    foreach (@{ $context{'subjectAltName'} }) {
      if    ( /^otherName=/ )                   { push @Errors, "X509: otherName not supported"; }
      elsif ( /^rfc822Name=([\x00\x07-\x0f\x11-\x14\x18-\x1b\x20-\x23\x25-\x7d\x7f]*)$/ )
                                                { $SubjectAltName.=ASN1Wrap("81",Hex($1)); }
      elsif ( /^dNSName=([\x00\x07-\x0f\x11-\x14\x18-\x1b\x20-\x23\x25-\x7d\x7f]*)$/ )
                                                { $SubjectAltName.=ASN1Wrap("82",Hex($1)); 
                                                  $host=1;
                                                }
      elsif ( /^x400Address=/ )                 { push @Errors, "X509: x400Address not supported"; }
      elsif ( /^directoryName=(30[0-9a-f]*)$/ ) { $SubjectAltName.=ASN1Wrap("84",$1); }
      elsif ( /^directoryName=(\060.*)$/ )      { $SubjectAltName.=ASN1Wrap("84",Hex($1)); }
      elsif ( /^ediPartyName=/ )                { push @Errors, "X509: ediPartyName not supported"; }
      elsif ( /^uniformResourceIdentifier=([\x00\x07-\x0f\x11-\x14\x18-\x1b\x20-\x23\x25-\x7d\x7f]*)$/ )
                                                { $SubjectAltName.=ASN1Wrap("86",Hex($1)); }
      elsif ( /^IPAddress=(.{4})$/ )            { $SubjectAltName.=ASN1Wrap("87",$1."ffffffff");
                                                  push @Warnings, "X509: Assuming IPv4Address has /32 Mask"; }
      elsif ( /^IPAddress=([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ )
                                                { $SubjectAltName.=ASN1Wrap("87",Hex(chr($1).chr($2).chr($3).chr($4))."ffffffff");
                                                  push @Warnings, "X509: Assuming IPv4Address has /32 Mask";}
      elsif ( /^IPAddress=([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ )
                                                { $SubjectAltName.=ASN1Wrap("87",Hex(chr($1).chr($2).chr($3).chr($4).chr($5).chr($6).chr($7).chr($8)));}
      elsif ( /^IPAddress=(.{8})$/ )            { $SubjectAltName.=ASN1Wrap("87",Hex($1)); }
      elsif ( /^IPAddress=(.{16})$/ )           { $SubjectAltName.=ASN1Wrap("87",Hex($1).("\xff" x 16));
                                                  push @Warnings, "X509: Assuming IPv6Address has /128 Mask"; }
      elsif ( /^registeredID=/ )                { push @Errors, "X509: registeredID not supported"; }
      elsif ( /^(rfc822Name|dNSName|directoryName|uniformResourceIdentifier|IPAddress)=/ )
                                                { push @Errors, "X509: Bad data for $1 subjectAlternitiveName"; }
      elsif ( /^([^=]+)=/ )                     { push @Errors, "X509: unknown generalName $1 for subjectAlternitiveName"; }
      else                                      { push @Errors, "X509: malformed SubjectAltName entry"; }
    }
    $SubjectAltName=ASN1Wrap("04",ASN1Wrap("30",$SubjectAltName));
    $SubjectAltNameExt=ASN1Wrap("30","0603551d11".$SubjectAltName);
  }

  my $BasicConstraints='30090603551d1304023000';  #CA False
  my $KU='300b0603551d0f0404030204b0'; #Digital Siganture, Key Encypherment, Digital Encryption
  my $EKU;
  if ( $host ) { $EKU='301d0603551d250416301406082b0601050507030106082b06010505070302';}
  else { $EKU='30130603551d25040c300a06082b06010505070302'; }

  $REQExt=ASN1Wrap("a0", ASN1Wrap("30", "06092a864886f70d01090e".ASN1Wrap("31", ASN1Wrap("30",$BasicConstraints.$KU.$EKU.$SubjectAltNameExt ))));  

#### The whole chunck of certificate to be signed ####
  my $TBSRequest=ASN1Wrap("30",$REQversion.$REQsubject.$REQsubjectPublicKeyInfo.$REQExt);

###Signature Bits#####################################################
# REQsignatureAlgorithm REQsignature

# Make Checksum and RSA sign it
#  my $REQsignature="300d06092a864886f70d0101040500"; #SEQ(OID:md5WithRSAEncryption NULL)
  my $REQsignature="300d06092a864886f70d0101050500"; #SEQ(OID:SHA1WithSHA1Encryption NULL)
  my $BinaryTBSRequest = $TBSRequest;
  $BinaryTBSRequest       =~ s/(..)/pack('C',hex($&))/ge;
  my $RSAsignedDigest      = digestSign("sha1WithRSA",$BinaryTBSRequest,Hex($KI{KeyprivateExponent}),Hex($KI{Keymodulus}));
  my $Signature            = ASN1Wrap("03",ASN1BitStr($RSAsignedDigest)); #(Always n*8 bits for MDnRSA and SHA1RSA)

###Wrap it all up Public Bits and Signature############################
# TBSCertificate X509signatureAlgorithm X509signature

  my $REQ                  = ASN1Wrap("30",$TBSRequest.$REQsignature.$Signature);

###Write out the Cert and Key files####################################

  $REQ=~s/(..)/pack('C',hex($&))/ge;
  $Privatekey=~s/(..)/pack('C',hex($&))/ge;

  return { Req=>$REQ, Key=>$Privatekey, Warnings=>\@Warnings };
}

1;

__END__

=head1 NAME

VOMS::Lite::REQ - Perl extension for PKCS #10 Certificate Request creation

=head1 SYNOPSIS

  use VOMS::Lite::REQ;
  %REQ= %{ VOMS::Lite::REQ::Create(
                                    {
                                      DN => ["C=GB","CN=my common name"],
                                      subjectAltName => ["rfc822Name=my.email@address.com"]
                                    }
                                 )
         };

  %REQ= %{ VOMS::Lite::REQ::Examine(
                                     {
                                       SubjectDN => "",
                                     }
                                   )
         };
=head1 DESCRIPTION

VOMS::Lite::REQ is primarily for internal use.  But frankly I don't mind if you use this package directly :-)

=head2 VOMS::Lite::REQ::Create

VOMS::Lite::REQ::Create takes one argument, an anonymous hash
containing all the relevant information required to make the
X509 Certificate.

  In the Hash the following scalars should be defined:
  'DN'     the array of attribute=value strings that make up the
     Distinguished Name

  The following may also be defined

  'Cert' the DER encoding of the issuing (CA) certificate.
  'Key'  the DER encoding of the issuing (CA) key.
  'Bits' the size of the key can be any of 512,1024,2048,4096

  'subjectAltName' a reference to an Array of Generalnames e.g.
            [ 'rfc822Name=mike.jones@manchester.ac.uk',
              'dNSName=a.dns.fqdn',
              'directoryName=300f310d300b060355040313044d696b65',
                 # The hex can also be specified as unsigned chars
              'uniformResourceIdentifier=http://www.mc.manchester.ac.uk/projects/shebangs/',
              'IPAddress=\202\130\001\202\377\377\377\377' ]

The return value is a hash containing the Certificate request and Key
strings in DER format (Req and Key), a reference to an array of
'Warnings' (a request will still be created if warnings are present) and
a reference to an array of 'Errors' (if an error is encountered then no
Proxy will be produced).

=head2 VOMS::Lite::REQ::Examine

VOMS::Lite::REQ::Examine takes two arguments: the DER encoded certificate request and a hash of the required information.
If defined in the hash of the first element in the call to Examine
the following variables will be parsed from the certificate and
returned in the return hash.
  Chuncks of DER encoded data directly from the certificate:
  'REQversion'                - DER encoded version
  'REQsubject'                - DER encoded subject
  'REQsubjectPublicKeyInfo'   - DER encoded subject Public Key Info
  'REQattributes'             - DER encoded attributes
  'REQSignatureAlgorithm'     - DER encoded Signature algorithem
  'REQSignatureValue'         - DER encoded Signature value

  Other useful values:
  'SubjectDN'                 - Subject's DN string, slash seperated
                                representation (yuk)
  'KeypublicExponent'         - hex 2's complement integer string 
                                e.g. '10001' = 65537 
  'Keymodulus'                - hex 2's complement integer string
  'SignatureValue'            - hex 2's complement integer string
  'SignatureType'             - one of 'md5WithRSA' 'sha1WithRSA' 
                                'md4WithRSA' 'md2WithRSA'

=head2 EXPORT

None by default;  

=head1 SEE ALSO

PKCS #10: Certification Request Syntax Specification http://tools.ietf.org/html/2986

This module was originally designed for the SHEBANGS project at The University of Manchester.
http://www.mc.manchester.ac.uk/projects/shebangs/
now http://www.rcs.manchester.ac.uk/research/shebangs/

Mailing list, shebangs@listserv.manchester.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 2009 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
