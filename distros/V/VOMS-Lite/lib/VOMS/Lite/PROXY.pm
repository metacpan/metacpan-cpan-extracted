package VOMS::Lite::PROXY;

use 5.004;
use strict;
use VOMS::Lite::PEMHelper qw(readCert readAC readPrivateKey);
use VOMS::Lite::CertKeyHelper qw(digestSign);
use VOMS::Lite::ASN1Helper qw(ASN1Wrap ASN1Unwrap DecToHex Hex ASN1BitStr);
use VOMS::Lite::KEY;
use VOMS::Lite::X509;
use VOMS::Lite::RSAKey;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

$VERSION = '0.20';

sub Examine {
  return VOMS::Lite::X509::Examine(@_);
}

sub Create {

# Load in Context
  my %context = %{ shift() };

# Create error and warning arrays
  my @Errors;
  my @Warnings;

# Get request time;
  my $now=time();

# Check for required input values
  if ( ! defined $context{'Cert'} )     { push @Errors, "PROXY: Issuer certificate not supplied"; }
  if ( ! defined $context{'Key'} )      { push @Errors, "PROXY: Issuer key not supplied"; }

# Bail if there isn't enough information
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

# Load input data into local variables
  my $CertInfoRef = (($context{'Cert'} =~ /^(\060.+)$/s) ? VOMS::Lite::X509::Examine($&, {X509serial=>"", X509subject=>"", End=>""}) : undef);
  my $KeyInfoRef  = (($context{'Key'}  =~ /^(\060.+)$/s) ?  VOMS::Lite::KEY::Examine($&, {Keymodulus=>"", KeyprivateExponent=>""}) : undef);
  my %CI; if ( defined $CertInfoRef )  { %CI=%$CertInfoRef; } else  { push @Errors, "PROXY: Unable to parse certificate."; }
  my %KI; if ( defined $KeyInfoRef )   { %KI=%$KeyInfoRef;  } else  { push @Errors, "PROXY: Unable to parse key."; }

# Bail if there is a certificate Parse error
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

# Load optional values
  my $type        = ((( defined  $context{'Type'}       && $context{'Type'}       =~ /^(Lega[cs]y|Limited|Pre-RFC|RFC)$/) ) ? $& : undef);
  if ( $type eq "Legasy" ) { $type = "Legacy"; $context{'Type'}="Legacy"; }  # oops was going through a bad spell! 
  my $pathlen     = ((( defined  $context{'PathLength'} && $context{'PathLength'} =~ /^([0-9]+)$/s) ) ?                    $& : undef);
  my $bits        = ((( defined  $context{'Bits'}       && $context{'Bits'}       =~ /^(512|1024|2048|4096)$/s) ) ?        $& : undef);
  my $lifetime    = ((( defined  $context{'Lifetime'}   && $context{'Lifetime'}   =~ /^([0-9]+)$/s) ) ?                    $& : undef);
  my $start       = ((( defined  $context{'Start'}      && $context{'Start'}      =~ /^([0-9]+)$/s) ) ?                    $& : undef);
  my $AC          = ((( defined  $context{'AC'}         && $context{'AC'}         =~ /^(\060.+)$/s) ) ?                    $& : undef);
  my @Ext;
  if ( defined $context{'Ext'} ) { 
    if ( ref ($context{'Ext'}) eq "ARRAY" ) { @Ext = @{ $context{'Ext'} }; }
    else { push @Errors,"PROXY: Ext must be an array reference"; } 
  };
  foreach (@Ext) { if ( ! /^(\060.+)$/ ) { push @Errors,"Extension ".Hex($1)." isn't DER encoded"; } }
  my $KeypublicE  = ((( defined  $context{'KeypublicExponent'} && $context{'KeypublicExponent'} =~ /^([\x00-\x7f].+)$/s) ) ? $& : undef);
  my $KeypublicM  = ((( defined  $context{'KeypublicModulus'} && $context{'KeypublicModulus'} =~ /^([\x00-\x7f].+)$/s) ) ? $& : undef);

# Check for unrecognised values for recognised options
  if ( defined $context{'Type'}       && ! defined $type )     { push @Errors, "PROXY: Unknown proxy type $context{'Type'}. Try Legacy, Limited, Pre-RFC or RFC."; }
  if ( defined $context{'PathLength'} && ! defined $pathlen )  { push @Errors, "PROXY: Invalid Pathlength $context{'PathLength'}. Must be a positive integer."; }
  if ( defined $context{'Bits'}       && ! defined $bits )     { push @Errors, "PROXY: Key size may only be 512, 1024, 2048 or 4096."; }
  if ( defined $context{'Lifetime'}   && ! defined $lifetime ) { push @Errors, "PROXY: Invalid Lifetime $context{'Lifetime'}. Must be a positive integer."; }
  if ( defined $context{'Start'}      && ! defined $start )    { push @Errors, "PROXY: Invalid Start $context{'Start'}. Must be a positive integer (seconds since epoch)."; }
  if ( defined $context{'AC'}         && ! defined $AC )       { push @Errors, "PROXY: AC Must be in DER format."; }

# Check for unknown options
  foreach (keys %context) { if ( ! /^(Quiet|Type|PathLength|Lifetime|AC|Ext|Cert|Key|Start|Bits|KeypublicExponent|KeypublicModulus)$/ ) { push @Errors, "PROXY: $_ is an invalid option.";}}

  if ( defined $start ) { $now = $start;}

# Bail if any recognised options are invalid
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

# Warn if there is something queer
  if ( ! defined $type )     { $type     = "Legacy";   push @Warnings, "PROXY: Undefined proxy type. Defaulting to Legacy."; }
  if ( ! defined $lifetime ) { $lifetime = 43200;      push @Warnings, "PROXY: Undefined lifetime. Defaulting to $lifetime seconds."; }
  if ( ! defined $bits )     { $bits = 512;            push @Warnings, "PROXY: Undefined key size. Defaulting to $bits bits."; }
  if ( $lifetime > 86400 )   {                         push @Warnings, "PROXY: Requested lifetime exceeds 24 hours."; }
  if ( ( $lifetime ) > ( $CI{'End'} - $now ) )       { push @Warnings, "PROXY: Requested lifetime exceeds lifetime of issuer."; }
  if ( ( $CI{'End'} - $now ) < 604800 )              { push @Warnings, "PROXY: Issuer certificate will expire in less than 1 week."; }
  if ( $type =~ "Legacy" && defined $pathlen )  { push @Warnings, "PROXY: Legacy Proxy may not a proxy pathlength."; }

###################################################################
# Do not edit below these lines (unless there's a bug of course!) #
###################################################################

#Get times  Now and Now + $lifetime (12 hours)
  my @NOW=gmtime($now );
  my @FUT=gmtime($now + $lifetime );

# UTCTIME (so two digit years, OK for the next 40 or so years!)
  my $beforeDate=sprintf("%02i%02i%02i%02i%02i%02iZ",($NOW[5] % 100),($NOW[4]+1),$NOW[3],$NOW[2],$NOW[1],$NOW[0]);
  my $afterDate=sprintf("%02i%02i%02i%02i%02i%02iZ",($FUT[5] % 100),($FUT[4]+1),$FUT[3],$FUT[2],$FUT[1],$FUT[0]);

  my ( $Keyversion, $Keymodulus, $KeypublicExponent, $KeyprivateExponent, $Keyprime1, $Keyprime2, $Keyexponent1, $Keyexponent2, $Keycoefficient, $Privatekey);

  if ( ! defined($KeypublicE) || ! defined($KeypublicM) ) {

# Generate Key Pair
    my $keyref = VOMS::Lite::RSAKey::Create( { Bits => $bits, Verbose => (defined $context{'Quiet'})?undef:"y" } );
    if ( ! defined $keyref ) { return { Errors => [ "PROXY: Key Generation Failure" ] } ; }
    my %key = %{ $keyref };
    if ( defined $key{'Errors'} ) { return { Errors => [ "PROXY: Error in Key Generation ".$key{'Errors'} ] } ; }

### Proxy Private Key#####################################################
#   Keyversion Keymodulus KeypublicExponent KeyprivateExponent
#   Keyprime1 Keyprime2 Keyexponent1 Keyexponent2 Keycoefficient
    $Keyversion =         "020100";
    $Keymodulus =         ASN1Wrap("02",DecToHex($key{Modulus}));
    $KeypublicExponent =  ASN1Wrap("02",DecToHex($key{PublicExponent}));
    $KeyprivateExponent = ASN1Wrap("02",DecToHex($key{PrivateExponent}));
    $Keyprime1 =          ASN1Wrap("02",DecToHex($key{Prime1}));
    $Keyprime2 =          ASN1Wrap("02",DecToHex($key{Prime2}));
    $Keyexponent1 =       ASN1Wrap("02",DecToHex($key{Exponent1}));
    $Keyexponent2 =       ASN1Wrap("02",DecToHex($key{Exponent2}));
    $Keycoefficient =     ASN1Wrap("02",DecToHex($key{Iqmp}));

    $Privatekey=ASN1Wrap("30",$Keyversion.$Keymodulus.$KeypublicExponent.$KeyprivateExponent.
                               $Keyprime1.$Keyprime2.$Keyexponent1.$Keyexponent2.$Keycoefficient);
  } else {
    $Keymodulus =         ASN1Wrap("02",Hex($KeypublicM));
    $KeypublicExponent =  ASN1Wrap("02",Hex($KeypublicE));
  }

###Proxy Public Bits######################################################
# TBSCertificate:
#  X509version X509serial X509signature X509issuer X509validity X509subject
#  X509subjectPublicKeyInfo (X509issuerUniqueID) (X509subjectUniqueID) X509extensions

#Certificate Version (x509 v3)
  my $X509version = "a003020102";

#Serial Number (different algorithm for (Pre)?RFC and Legacy Globus
  my $SN=DecToHex( ((($CI{End}-$now) & hex("00ffffff"))<<8 ) + int(rand 256));
  my $X509serial=($type eq "Legacy")?Hex($CI{X509serial}):ASN1Wrap("02",$SN);

#Use MD5 and RSA for now
  my $X509signature="300d06092a864886f70d0101040500"; #SEQ(OID:md5WithRSAEncryption NULL)

#Issuer (straight from certificate)
  my $X509issuer=Hex($CI{X509subject});

#Validity
  my $X509Validity=ASN1Wrap("30",ASN1Wrap("17",Hex($beforeDate)).ASN1Wrap("17",Hex($afterDate)));

#Subject
  my $proxystr = Hex("proxy");
  $proxystr    = Hex("limited proxy") if ($type eq "Limited");
  $proxystr    = Hex(hex($SN)) if ($type ne "Legacy" && $type ne "Limited");
  my $PROXYNAME=ASN1Wrap("31",ASN1Wrap("30","0603550403".ASN1Wrap("13",$proxystr)));  #SET{SEQ{OID:CN CN}}
  my $X509subject=ASN1Wrap("30",Hex(scalar ASN1Unwrap($CI{X509subject})).$PROXYNAME);

#Public Key
  my $PubKeyChunck=ASN1Wrap("30",$Keymodulus.$KeypublicExponent);
  my $X509subjectPublicKeyInfo=ASN1Wrap("30",ASN1Wrap("30","06092a864886f70d0101010500").ASN1Wrap("03",ASN1BitStr($PubKeyChunck)));

#Extensions
#KeyUsage
  my $keyusage=ASN1Wrap("30","0603551d0f"."0101ff"."0404030203a8");#Critical:Dig sign & Key encypher & Key Agree
######Proxyinfo not quite right yet
#ProxyInfo Extensions SEQ{OID(GlobusProxy|id-ppl-inheritALL) . Criticality . PolicyLangOID+Policy}
  my $PolicyVal=( defined $pathlen )?ASN1Wrap("a1",ASN1Wrap("02",DecToHex($pathlen))):"";
  my $Policy;
  $Policy=ASN1Wrap("04",ASN1Wrap("30","300a06082b06010505071501".$PolicyVal)) if ($type eq "Pre-RFC");
  $Policy=ASN1Wrap("04",ASN1Wrap("30",$PolicyVal."300a06082b06010505071501")) if ($type eq "RFC");
  my $ProxyInfo="";
  $ProxyInfo=ASN1Wrap("30","060a2b060104019b5001815e"."0101ff".$Policy) if ($type eq "Pre-RFC");
  $ProxyInfo=ASN1Wrap("30","06082b0601050507010e".    "0101ff".$Policy) if ($type eq "RFC");
#VOMS
  my $VOMS="";
#  $VOMS=ASN1Wrap("30","060a2b06010401be45646405"."".ASN1Wrap("04",Hex($AC))) if ( defined $AC );
  $VOMS=ASN1Wrap("30","060a2b06010401be45646405"."".ASN1Wrap("04",ASN1Wrap("30",ASN1Wrap("30",Hex($AC))))) if ( defined $AC );

  my $X509extensions=ASN1Wrap("a3",ASN1Wrap("30",$keyusage.$ProxyInfo.$VOMS.Hex(join('',@Ext))));

#The whole chunck of certificate to be signed
  my $TBSCertificate=ASN1Wrap("30",$X509version.$X509serial.$X509signature.$X509issuer.$X509Validity.
                                   $X509subject.$X509subjectPublicKeyInfo.$X509extensions);

###Signature Bits#####################################################
# X509signatureAlgorithm X509signature

# Make MD5 Checksum and RSA sign it
  my $BinaryTBSCertificate = $TBSCertificate;
  $BinaryTBSCertificate   =~ s/(..)/pack('C',hex($&))/ge;
  my $RSAsignedDigest      = digestSign("md5WithRSA",$BinaryTBSCertificate,Hex($KI{KeyprivateExponent}),Hex($KI{Keymodulus}));
  my $Signature            = ASN1Wrap("03",ASN1BitStr($RSAsignedDigest)); #(Always n*8 bits for MDnRSA and SHA1RSA)


###Wrap it all up Public Bits and Signature############################
# TBSCertificate X509signatureAlgorithm X509signature

  my $Certificate             = ASN1Wrap("30",$TBSCertificate.$X509signature.$Signature);

###Write out the proxy to the proxy file###############################
# ProxyCert ProxyKey SigningCerts ##### Would like to put full chain in here!

  $Certificate=~s/(..)/pack('C',hex($&))/ge;
  if ( ! defined($KeypublicE) || ! defined($KeypublicM) ) { $Privatekey=~s/(..)/pack('C',hex($&))/ge; }

  return { ProxyCert=>$Certificate, ProxyKey=>$Privatekey, Warnings=>\@Warnings };
}

1;

__END__

=head1 NAME

VOMS::Lite::PROXY - Perl extension for GSI Proxy Impersonation certificate creation

=head1 SYNOPSIS

  use VOMS::Lite::PROXY;
  %PROXY= %{ VOMS::Lite::PROXY::Create(%inputref) };
  
=head1 DESCRIPTION

VOMS::Lite::PROXY::Create takes one argument, a hash containing all the relevant 
information required to make the Proxy Certificate.  
  In the Hash the following scalars should be defined:
  'Cert' the DER encoding of the proxy issuing certificate.
  'Key'  the DER encoding of the proxy issuing key.

  The following are optional
  'Lifetime' the integer lifetime of the credential to be issued in seconds
  'PathLength' restricts the proxy by embedding policy to not allow more than PathLength proxy certificate in any chain derived from the credential produced (RFC and Pre-RFC only).
  'AC' A DER encoded VOMS credential
  'Type' the type of proxy to create (can be any of Legacy, Limited, Pre-RFC, RFC. The default is Legacy.)

The return value is a hash containing the PROXY Certificate and Key strings in DER format (ProxyCert and ProxyKey),
a reference to an array of warnings (an Proxy will still be created if warnings are present),
a reference to an array of errors (if an error is encountered then no Proxy will be produced).

=head2 EXPORT

None by default;  

=head1 SEE ALSO

RFC3820, RFC3281 and the VOMS Attribute Specification document from the OGSA Athuz Working Group of the Open Grid Forum http://www.ogf.org.  
Also see gLite from the EGEE.

This module was originally designed for the SHEBANGS project at The University of Manchester.
http://www.rcs.manchester.ac.uk/projects/shebangs/

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
