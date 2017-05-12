package VOMS::Lite::X509;

use 5.004;
use strict;
use VOMS::Lite::ASN1Helper qw(ASN1OIDtoOID ASN1Index ASN1Wrap ASN1Unwrap ASN1UnwrapHex DecToHex Hex ASN1BitStr OIDtoASN1OID);
use VOMS::Lite::KEY;
use Digest::SHA1 qw(sha1_hex);
use Digest::MD5 qw(md5);
use Time::Local qw(timegm);
use VOMS::Lite::RSAKey;
use VOMS::Lite::CertKeyHelper;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

$VERSION = '0.20';

sub Examine {
  my ($decoded,$dataref)=@_;
  my %Values=%$dataref;
  my @ASN1Index=ASN1Index($decoded);

  return ( {Errors=>["Unable to parse certificate"]} ) if (@ASN1Index==0);

  my ($index,$ignoreuntil)=(0,0);
  my ($X509TBSCert,$X509version,$X509serial,$X509signature,$X509issuer,$X509validity,$X509subject,
      $X509subjectPublicKeyInfo,$X509issuerUniqueID,$X509subjectUniqueID,$X509extensions,
      $X509SignatureAlgorithm,$X509SignatureValue);

# Drill down into the certificate
  shift @ASN1Index; # skip the wrapping of the certificate sequence
  my $TBSCertRef=shift @ASN1Index; #CertificateTBS Sequence
  if (defined $Values{X509TBSCert}) {
    my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @$TBSCertRef;
    $Values{X509TBSCert}=substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));
  }

# Extract the main components of the certificate
  foreach (@ASN1Index) {
    my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @$_;
    if ( $HEADSTART < $ignoreuntil ) { next; }
    else {
      if    ($index==0 && $CLASS==2 && $TAG==0)  {$X509version = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==1 && $TAG==2)  {$X509serial               = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==2 && $TAG==16) {$X509signature            = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==3 && $TAG==16) {$X509issuer               = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==4 && $TAG==16) {$X509validity             = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==5 && $TAG==16) {$X509subject              = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==6 && $TAG==16) {$X509subjectPublicKeyInfo = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==7 && $CLASS==2 && $TAG==1) {$X509issuerUniqueID  = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==7 && $CLASS==2 && $TAG==2) {$X509subjectUniqueID = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==7 && $CLASS==2 && $TAG==3) {$X509extensions      = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==7 && $TAG==16) {$X509SignatureAlgorithm   = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));$index++;}
      elsif ($index==8 && $TAG==3) {$X509SignatureValue       = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      $ignoreuntil=$HEADSTART+$HEADLEN+$CHUNKLEN;
    }
}
  if ($index != 8) {return undef;} #Failed to read certificate

#Standard
  if (defined $Values{X509version})              {$Values{X509version}=$X509version;}
  if (defined $Values{X509serial})               {$Values{X509serial}=$X509serial;}
  if (defined $Values{X509signature})            {$Values{X509signature}=$X509signature;}
  if (defined $Values{X509issuer})               {$Values{X509issuer}=$X509issuer;}
  if (defined $Values{X509validity})             {$Values{X509validity}=$X509validity;}
  if (defined $Values{X509subject})              {$Values{X509subject}=$X509subject;}
  if (defined $Values{X509subjectPublicKeyInfo}) {$Values{X509subjectPublicKeyInfo}=$X509subjectPublicKeyInfo;}
  if (defined $Values{X509issuerUniqueID})       {$Values{X509issuerUniqueID}=$X509issuerUniqueID;}
  if (defined $Values{X509subjectUniqueID})      {$Values{X509subjectUniqueID}=$X509subjectUniqueID;}
  if (defined $Values{X509extensions})           {$Values{X509extensions}=$X509extensions;}
  if (defined $Values{X509SignatureValue})       {$Values{X509SignatureValue}=$X509SignatureValue;}

##################
# Helpers  -- Deeper parsing of certificate

# Values of Start and End Time Seconds since Epoch
  if (defined $Values{Start} || defined $Values{End}) {
    my @validity=ASN1Unwrap($X509validity);
    my @st=ASN1Unwrap($validity[5]);
    my @et=ASN1Unwrap(substr($validity[5],$st[0]+$st[1]));
    if    ( $st[4] eq "23" && $st[5]=~ /^(..)(..)(..)(..)(..)(..)Z$/ )   { $Values{Start} = timegm($6,$5,$4,$3,($2-1),$1); }
    elsif ( $st[4] eq "24" && $st[5]=~ /^(....)(..)(..)(..)(..)(..)Z$/ ) { $Values{Start} = timegm($6,$5,$4,$3,($2-1),$1); }
    if    ( $et[4] eq "23" && $et[5]=~ /^(..)(..)(..)(..)(..)(..)Z$/ )   { $Values{End}   = timegm($6,$5,$4,$3,($2-1),$1); }
    elsif ( $et[4] eq "24" && $et[5]=~ /^(....)(..)(..)(..)(..)(..)Z$/ ) { $Values{End}   = timegm($6,$5,$4,$3,($2-1),$1); }
  }

# The String Repersentation of the subject and issuer DNs
  if (defined $Values{SubjectDN} || defined $Values{Proxy}) {
    my @ASN1SubjectDNIndex=ASN1Index($X509subject);
    shift @ASN1SubjectDNIndex;
    $Values{SubjectDN}="";
    while (@ASN1SubjectDNIndex) {
      my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN)=(0,0,0,0,0);
      until ($TAG == 6 ) { ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ASN1SubjectDNIndex}; }
      my $OID=substr($X509subject,($HEADSTART+$HEADLEN),$CHUNKLEN);
      ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ASN1SubjectDNIndex};
      my $Value=substr($X509subject,($HEADSTART+$HEADLEN),$CHUNKLEN);
      $Values{SubjectDN}.="/".VOMS::Lite::CertKeyHelper::OIDtoDNattrib(ASN1OIDtoOID($OID))."=$Value";
    }
  }
  if (defined $Values{IssuerDN} || defined $Values{Proxy}) {
    my @ASN1IssuerDNIndex=ASN1Index($X509issuer);
    shift @ASN1IssuerDNIndex;
    $Values{IssuerDN}="";
    while (@ASN1IssuerDNIndex) {
      my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN)=(0,0,0,0,0);
      until ($TAG == 6 ) { ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ASN1IssuerDNIndex}; }
      my $OID=substr($X509issuer,($HEADSTART+$HEADLEN),$CHUNKLEN);
      ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ASN1IssuerDNIndex};
      my $Value=substr($X509issuer,($HEADSTART+$HEADLEN),$CHUNKLEN);
      $Values{IssuerDN}.="/".VOMS::Lite::CertKeyHelper::OIDtoDNattrib(ASN1OIDtoOID($OID))."=$Value";
    }
  }

# Public key and Modulus
  if ( defined $Values{KeypublicExponent} || defined $Values{Keymodulus} ) {
    my ($OID,$modexpbitstr);
    my @KeyIndex=ASN1Index($X509subjectPublicKeyInfo);
    foreach (@KeyIndex) {
      my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @$_;
      if ( ! $CONSTRUCTED ) {
        $OID=Hex(substr($X509subjectPublicKeyInfo,($HEADSTART+$HEADLEN),$CHUNKLEN)) if ( $TAG == 6 );
        $modexpbitstr=substr($X509subjectPublicKeyInfo,($HEADSTART+$HEADLEN),$CHUNKLEN) if ( $TAG == 3 );
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

# Issuer and Subject Hashes
  if (defined $Values{Hash}) {
    my $data=md5($X509subject);
    $Values{Hash}=Hex( substr($data,3,1).substr($data,2,1).substr($data,1,1).substr($data,0,1) );
  }
  if (defined $Values{IHash}) {
    my $data=md5($X509issuer);
    $Values{IHash}=Hex( substr($data,3,1).substr($data,2,1).substr($data,1,1).substr($data,0,1) );
  }

# SSLv3 Certificate extensions
  my @Exts=(1,1,1,1,1,$X509extensions,1);
  my @ExtIndex=ASN1Index($X509extensions);
  shift (@ExtIndex) ; shift @ExtIndex;  #unwrap twice from tag 3
  while (@ExtIndex) {

#   Get OID
    my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN)=(0,0,0,0,0);
    until ($TAG == 6 ) { ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ExtIndex}; }
    my $OID=substr($X509extensions,($HEADSTART+$HEADLEN),$CHUNKLEN);
#   Calculate OID string value
    my $OIDstr=ASN1OIDtoOID($OID);

#   Check for Criticality and get data
    ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ExtIndex};
    my $CRITICAL=0;
    if ($TAG == 1) { # Check Criticality
      $CRITICAL=ord(substr($X509extensions,($HEADSTART+$HEADLEN+2),1));
      ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ExtIndex};
    }
    my $Value=substr($X509extensions,($HEADSTART+$HEADLEN),$CHUNKLEN);

# Return Extension if requested
    if (defined $Values{"Extension:$OIDstr"} ) {
      $Values{"Extension:$OIDstr"} = $Value;
    }

# GSI Proxy (check for Pre-RFC and RFC)
    if (defined $Values{ProxyInfo}      &&     # Has Proxyinfo been requested
        ( $OIDstr eq "1.3.6.1.5.5.7.1.14" || $OIDstr eq "1.3.6.1.4.1.3536.1.222" ) ) {
      next if ( ! $CRITICAL );  # MUST be critical (if it's not we can ignore it anyhow)
      my $ProxyPolicy;
      my $PCI                          = ASN1Unwrap($Value);
      my $PType                        = ( $OIDstr eq "1.3.6.1.5.5.7.1.14" ) ? "RFC" : "Pre-RFC";
      $Values{"ProxyInfo"}            .= ( $Values{"ProxyInfo"} eq "" ) ? "$PType" : ":$PType"; #Could have both ProxyInfo
      $Values{"ProxyInfo$PType"}       = $PCI;
      $Values{"ProxyPolicyOID$PType"}  = undef;
      $Values{"ProxyPolicy$PType"}     = undef;
      $Values{"ProxyPathlen$PType"}    = undef;
      until (length($PCI) == 0) {  # Get the first level
        my ($headlen,$reallen,$Class,$Constructed,$Tag,$str)=ASN1Unwrap($PCI);
        $PCI=substr($PCI,($headlen+$reallen));
        if ($Tag==16)                        { $ProxyPolicy=$str; }
        elsif ( $Tag==2 && $PType eq "RFC" ) { $Values{"ProxyPathlen$PType"}=ord($str); }
        elsif ( $Tag==1 )                    { $Values{"ProxyPathlen$PType"}=ord(ASN1Unwrap($str)); }
      }
      until (length($ProxyPolicy) == 0) {
        my ($headlen,$reallen,$Class,$Constructed,$Tag,$str)=ASN1Unwrap($ProxyPolicy);
        $ProxyPolicy=substr($ProxyPolicy,($headlen+$reallen));
        if ($Tag==6)     { $Values{"ProxyPolicyOID$PType"}=$str; }
        elsif ($Tag==4)  { $Values{"ProxyPolicy$PType"}=$str; }
      }
      next;
    }

# Subject Alternative Name
    if (defined $Values{subjectAltName} && $OIDstr eq "2.5.29.17" ) {
      my $SAN=ASN1Unwrap($Value);
      $Values{subjectAltName}=scalar ASN1Unwrap($Value);
      my @SAN;
      until (length($SAN) == 0) {
        my ($headlen,$reallen,$Class,$Constructed,$Tag,$str)=ASN1Unwrap($SAN);
        $SAN=substr($SAN,($headlen+$reallen));
        if    ($Tag==0) {push @SAN,"otherName=$str"}
        elsif ($Tag==1) {push @SAN,"rfc822Name=$str";}
        elsif ($Tag==2) {push @SAN,"dNSName=$str";}
        elsif ($Tag==3) {push @SAN,"x400Address=$str";}
        elsif ($Tag==4) {push @SAN,"directoryName=$str";}
        elsif ($Tag==5) {push @SAN,"ediPartyName=$str";}
        elsif ($Tag==6) {push @SAN,"uniformResourceIdentifier=$str";}
        elsif ($Tag==7) {push @SAN,"IPAddress=$str";}
        elsif ($Tag==8) {push @SAN,"registeredID=$str";}
      }
      $Values{subjectAltNameArray}=\@SAN;
      next;
    }

# Issuer Alternative Name
    if (defined $Values{issuerAltName} && $OIDstr eq "2.5.29.18" ) {
      my $IAN=ASN1Unwrap($Value);
      $Values{issuerAltName}=scalar ASN1Unwrap($Value);
      my @IAN;
      until (length($IAN) == 0) {
        my ($headlen,$reallen,$Class,$Constructed,$Tag,$str)=ASN1Unwrap($IAN);
        $IAN=substr($IAN,($headlen+$reallen));
        if    ($Tag==0) {push @IAN,"otherName=$str"}
        elsif ($Tag==1) {push @IAN,"rfc822Name=$str";}
        elsif ($Tag==2) {push @IAN,"dNSName=$str";}
        elsif ($Tag==3) {push @IAN,"x400Address=$str";}
        elsif ($Tag==4) {push @IAN,"directoryName=$str";}
        elsif ($Tag==5) {push @IAN,"ediPartyName=$str";}
        elsif ($Tag==6) {push @IAN,"uniformResourceIdentifier=$str";}
        elsif ($Tag==7) {push @IAN,"IPAddress=$str";}
        elsif ($Tag==8) {push @IAN,"registeredID=$str";}
      }
      $Values{issuerAltNameArray}=\@IAN;
      next;
    }

# Subject Key Identifier
    if (defined $Values{subjectKeyIdentifier} && $OIDstr eq "2.5.29.14" ) {
      my $SKI=ASN1Unwrap($Value);
      $Values{subjectKeyIdentifier}=scalar ASN1Unwrap($Value);
      next;
    }
# Authority key identifier
    elsif (defined $Values{authorityKeyIdentifier} && $OIDstr eq "2.5.29.35" ) {
      my $AKI=ASN1Unwrap($Value);
      $Values{authorityKeyIdentifier}=$AKI;
      $Values{authorityKeyIdentifierSkid} = undef;   #explicitly undefine these incase they were set in the call!
      $Values{authorityKeyIdentifierIssuer} = undef; #
      $Values{authorityKeyIdentifierSerial} = undef; #
      until (length($AKI) == 0) {
        my ($headlen,$reallen,$Class,$Constructed,$Tag,$str)=ASN1Unwrap($AKI);
        $AKI=substr($AKI,($headlen+$reallen));
        if    ($Tag==0) {$Values{authorityKeyIdentifierSkid}=$str;}
        elsif ($Tag==1) {$Values{authorityKeyIdentifierIssuer}=$str;}
        elsif ($Tag==2) {$Values{authorityKeyIdentifierSerial}=Hex($str);}
      }
      next;
    }
# Key Usage
    elsif (defined $Values{keyUsage} && $OIDstr eq "2.5.29.15" ) {
      my $KU=ASN1Unwrap($Value);
      my $ignore;
      if ($KU =~ s/^(.)//) { $ignore = ord($1); }
      my @B;
      $KU =~ s|(.)|push @B,split(//, unpack("B*", $&))|ge;
      splice @B,-$ignore;
      $Values{keyUsage}=unpack("N", pack("B32",substr("0" x 32 . join("",@B), -32 )));
      $Values{keyUsageDigitalSignature} = (defined $B[0])?$B[0]:0;
      $Values{keyUsageNonRepudiation}   = (defined $B[1])?$B[1]:0;
      $Values{keyUsageKeyEncipherment}  = (defined $B[2])?$B[2]:0;
      $Values{keyUsageDataEncipherment} = (defined $B[3])?$B[3]:0;
      $Values{keyUsageKeyAgreement}     = (defined $B[4])?$B[4]:0;
      $Values{keyUsageKeyCertSign}      = (defined $B[5])?$B[5]:0;
      $Values{keyUsageCRLSign}          = (defined $B[6])?$B[6]:0;
      $Values{keyUsageEncipherOnly}     = (defined $B[7])?$B[7]:0;
      $Values{keyUsageDecipherOnly}     = (defined $B[8])?$B[8]:0;
      next;
    }
# Basic Constraints
    elsif (defined $Values{basicConstraints} && $OIDstr eq "2.5.29.19" ) {
      my $BC=ASN1Unwrap($Value);
      $Values{basicConstraints} = $BC;
      $Values{basicConstraintsCA} = 0; #explicitly undefine these incase they were set in the call!
      $Values{basicConstraintsPathLen} = undef;
      if ($BC =~ /\x01\x01(.)(.*)/) {
        $Values{basicConstraintsCA} = ord($1);
        if ($2 =~ /(.+)/) { $Values{basicConstraintsPathLen} = unpack("N",ASN1Unwrap($1));}
      }
      next;
    }
  }

# Signature Value
  if (defined $Values{SignatureValue} || defined $Values{SignatureType}) {
    $Values{SignatureValue}=substr(ASN1Unwrap($X509SignatureValue),1);
    my $HexX509signature=Hex($X509signature);
    if    ( $HexX509signature eq "300d06092a864886f70d0101040500" ) { $Values{SignatureType}="md5WithRSA"; }
    elsif ( $HexX509signature eq "300d06092a864886f70d0101050500" ) { $Values{SignatureType}="sha1WithRSA"; }
    elsif ( $HexX509signature eq "300d06092a864886f70d0101030500" ) { $Values{SignatureType}="md4WithRSA"; }
    elsif ( $HexX509signature eq "300d06092a864886f70d0101020500" ) { $Values{SignatureType}="md2WithRSA"; }
    else  { $Values{SignatureType}="unrecognised"; }
  }
  return (\%Values);
}

#########################################################

sub Create {

# Load in Context
  my %context = %{ shift() };

# Create error and warning arrays
  my @Errors; my @Warnings;

# Get request time;
  my $now=time();

# Check for required input values
  if ( ! defined $context{'DN'} )                                    { push @Errors,   "X509: Distinguished Name not supplied"; }
  if ( ! defined $context{'Serial'} )                                { push @Errors,   "X509: Serial number not supplied"; }
  if ( ! defined $context{'CACert'} && defined $context{'CAKey'} )   { push @Errors,   "X509: Issuer key supplied but certificate not supplied"; }
  if ( ! defined $context{'CAKey'}  && defined $context{'CACert'} )  { push @Errors,   "X509: Issuer certificate supplied but key not supplied"; }
  if ( ! defined $context{'CACert'} && ! defined $context{'CAKey'} ) { push @Warnings, "X509: Issuer not supplied creating Self signed certificate"; }
  if ( ! defined $context{'CACert'} && ! defined $context{'CA'} )    { push @Warnings, "X509: CA Assuming this is a CA"; $context{'CA'}="True"; }
  if ( ! defined $context{'CA'}     && defined $context{'CACert'} )  { push @Warnings, "X509: CA Assuming this is not a CA"; $context{'CA'}="False"; }

# Bail if there isn't enough information
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

# Check input values
  if (ref($context{'DN'}) ne "ARRAY" )                { push @Errors, "X509: DN Must be a reference to an array of distinguished name component strings."; }
  if ( defined ($context{'Extensions'}) && 
       ref($context{'Extensions'}) ne "ARRAY" )       { push @Errors, "X509: Extensions must be passed by reference to an array of DER encoded extensions."; }
  if ( $context{'Serial'} !~ /^([0-9]+)$/ )           { push @Errors, "X509: Serial number was not a positive integer"; }
  if ( $context{'CA'} !~ /^(False|True)$/ )           { push @Errors, "X509: CA valus can be only \"True\" or \"False\""; }
  if ( defined $context{'Lifetime'} && 
       $context{'Lifetime'} !~ /^[0-9]+$/)            { push @Errors, "X509: Invalid Lifetime $context{'Lifetime'}. Must be a +ve int."; }
  if ( defined $context{'Bits'} && 
       $context{'Bits'} !~ /^(512|1024|2048|4096)$/ ) { push @Errors, "X509: Key size can only be 512, 1024, 2048 or 4096."; }
  if ( defined $context{'SubjectAltName'} &&
       ref($context{'SubjectAltName'}) ne "ARRAY" )   { push @Errors, "X509: Extensions must be passed by reference to an array of generalnames."; }

# Bail if inputs are not the right format
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

# Load input data into local variables
  my ($CertInfoRef,$KeyInfoRef)=(undef,undef);
  my %CI;
  my %KI;
  if ( defined $context{'CACert'} ) {
    $CertInfoRef = (($context{'CACert'} =~ /^(\060.+)$/s) ? Examine($&, {X509issuer=>"", X509subject=>"", End=>"", subjectKeyIdentifier=>"", X509serial=>"", subjectAltName=>""}) : undef);
    $KeyInfoRef  = (($context{'CAKey'}  =~ /^(\060.+)$/s) ?  VOMS::Lite::KEY::Examine($&, {Keymodulus=>"", KeyprivateExponent=>""}) : undef);
    if ( defined $CertInfoRef )  { %CI=%$CertInfoRef; } else  { push @Errors, "X509: Unable to parse CA certificate."; } 
    if ( %CI && defined $CI{'Errors'} ) { push @Errors, "X509: Unable to parse CA certificate errors: ".join ('; ',@{ $CI{'Errors'}}); } 
    if ( defined $KeyInfoRef )   { %KI=%$KeyInfoRef;  } else  { push @Errors, "X509: Unable to parse CA key."; }    
  }

# Bail if there is a certificate Parse error
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

# Check for unknown options
  foreach (keys %context) { if ( ! /^(DN|subjectAltName|Quiet|Serial|CACert|CAKey|CA|Bits|Lifetime)$/ ) {push @Errors, "X509: $_ is an invalid option.";}}

# Bail if any recognised options are invalid
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

# Warn if there is something queer
  if ( ! defined $context{'Lifetime'} ) { $context{'Lifetime'} = 43200; push @Warnings, "X509: Undefined lifetime. Defaulting to $context{'Lifetime'} seconds."; }
  if ( ! defined $context{'Bits'} )     { $context{'Bits'} = 1024; push @Warnings, "X509: Undefined key size. Defaulting to $context{'Bits'} b."; }
  if ( defined $context{'CACert'} ) {
    if ( ( $context{'Lifetime'} ) > ( $CI{'End'} - $now ) ) { push @Warnings, "X509: Requested lifetime exceeds lifetime of issuer."; }
    if ( ( $CI{'End'} - $now ) < 604800 )                   { push @Warnings, "X509: Issuer certificate will expire in less than 1 week."; }
  }

#Get times. Now and Now + $lifetime
  my @NOW=gmtime($now);
  my @FUT=gmtime($now+$context{'Lifetime'});

# UTCTIME (so two digit years, OK for the next 40 or so years!)
  my $beforeDate=sprintf("%02i%02i%02i%02i%02i%02iZ",($NOW[5] % 100),($NOW[4]+1),$NOW[3],$NOW[2],$NOW[1],$NOW[0]);
  my $afterDate=sprintf("%02i%02i%02i%02i%02i%02iZ",($FUT[5] % 100),($FUT[4]+1),$FUT[3],$FUT[2],$FUT[1],$FUT[0]);

# Check and parse the DN array referenced
  my $ASN1DN="";
  foreach (@{ $context{'DN'} }) { 
    my ($attrib,$value)=split(/=/,$_,2); # Splits attribute and value
    my $OID = VOMS::Lite::CertKeyHelper::DNattribToOID($attrib);    # Convert Attribute to dot representation e.g. CN -> 2.5.4.3
    if ( defined $OID ) {
      my $STRtype;
      if    ( $value =~ /^[a-zA-Z0-9 \x22()+,.\/:?-]*$/ )                              { $STRtype="13"; } # Printable String
      elsif ( $value =~ /^[\x00\x07-\x0f\x11-\x14\x18-\x1b\x20-\x23\x25-\x7d\x7f]*$/ ) { $STRtype="16"; } #IA5 String
      else { push @Errors, "X509: Can't find an apropriate encoding for $attrib+$value."; }
      if ( defined $STRtype ) { $ASN1DN .= ASN1Wrap("31",ASN1Wrap("30",ASN1Wrap("06",Hex(OIDtoASN1OID($OID))).ASN1Wrap($STRtype,Hex($value)))) }; 
    }
    else { push @Errors, "X509: unknown Attribute: $attrib"; }
  }
  if ( $ASN1DN eq "" ) { push @Errors, "X509: No Attributes in Distunguished Name"; } ;
  $ASN1DN=ASN1Wrap("30",$ASN1DN); # The DN in an apropriate X.509 ASN1 structure.

# Make hash name
  my $Hash=$ASN1DN;
  $Hash =~ s/(..)/pack("C",hex($&))/ge;
  $Hash  = md5($Hash);
  $Hash  = Hex( substr($Hash,3,1).substr($Hash,2,1).substr($Hash,1,1).substr($Hash,0,1) );

# Check and parse the SubjectAltName array referenced
  my $SubjectAltName="";
  if ( defined $context{'subjectAltName'} ) {
    foreach (@{ $context{'subjectAltName'} }) { 
      if    ( /^otherName=/ )                   { push @Errors, "X509: otherName not supported"; } 
#      elsif ( /^rfc822Name=([\x00\x07-\x0f\x11-\x14\x18-\x1b\x20-\x23\x25-\x7d\x7f]*)$/ )
      elsif ( /^rfc822Name=([\x00-\x7f]*)$/ ) #IA5String -- Misconception that DNS is only [a-zA-Z0-9.-]*
                                                { $SubjectAltName.=ASN1Wrap("81",Hex($1)); }
#      elsif ( /^dNSName=([\x00\x07-\x0f\x11-\x14\x18-\x1b\x20-\x23\x25-\x7d\x7f]*)$/ )
      elsif ( /^dNSName=([\x00-\x7f]*)$/ ) #IA5String -- Misconception that DNS is only [a-zA-Z0-9.-]*
                                                { $SubjectAltName.=ASN1Wrap("82",Hex($1)); }
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
  }

# Get Set issuerAltName
  my $IssuerAltName="";
  if ( defined $context{'CACert'} && $CI{subjectAltName} ne "" )  { $IssuerAltName=ASN1Wrap("04",ASN1Wrap("30",Hex($CI{subjectAltName}))); }
  elsif ( ! defined $context{'CACert'} && $SubjectAltName ne "" ) { $IssuerAltName=$SubjectAltName; }

# Get Extensions 
  my $ExtraExts="";
  foreach ( @{ $context{'Extensions'} } ) {
    if ( /^\060/ ) { $ExtraExts.=Hex($_); }
    elsif ( /^30[0-9a-f]*$/ ) { $ExtraExts.=$_; }
    else { push @Errors,"X509: The format of an extension was not understood."; }
  }

# Bail if DN is bad or extension was not DER or hex DER
  if ( @Errors > 0 ) { return { Errors => \@Errors} ; }

# Generate Key Pair
  my $keyref = VOMS::Lite::RSAKey::Create( { Bits => $context{'Bits'}, Verbose => (defined $context{'Quiet'})?undef:"y" } );
  if ( ! defined $keyref ) { return { Errors => [ "X509: Key Generation Failure" ] } ; }
  my %key = %{ $keyref };
  if ( defined $key{'Error'} ) { return { Errors => [ "X509: Error in Key Generation ".$key{'Error'} ] } ; }


###############################
#OK Let's create an X509 Cred!#
###############################

### Create Key Pair ######################################################

#   Keyversion Keymodulus KeypublicExponent KeyprivateExponent
#   Keyprime1 Keyprime2 Keyexponent1 Keyexponent2 Keycoefficient
  my $Keyversion =         "020100";
  my $Keymodulus =         ASN1Wrap("02",DecToHex($key{Modulus}));
  my $KeypublicExponent =  ASN1Wrap("02",DecToHex($key{PublicExponent}));
  my $KeyprivateExponent = ASN1Wrap("02",DecToHex($key{PrivateExponent}));
  my $Keyprime1 =          ASN1Wrap("02",DecToHex($key{Prime1}));
  my $Keyprime2 =          ASN1Wrap("02",DecToHex($key{Prime2}));
  my $Keyexponent1 =       ASN1Wrap("02",DecToHex($key{Exponent1}));
  my $Keyexponent2 =       ASN1Wrap("02",DecToHex($key{Exponent2}));
  my $Keycoefficient =     ASN1Wrap("02",DecToHex($key{Iqmp}));

  my $Privatekey=ASN1Wrap("30",$Keyversion.$Keymodulus.$KeypublicExponent.$KeyprivateExponent.
                               $Keyprime1.$Keyprime2.$Keyexponent1.$Keyexponent2.$Keycoefficient);

# If this is to be selfsigned, set the CA's private key and modulus
  if ( ! defined $context{'CACert'} ) { 
    $KI{Keymodulus}=DecToHex($key{Modulus});
    $KI{KeyprivateExponent}=DecToHex($key{PrivateExponent});
    $KI{Keymodulus} =~ s/(..)/pack("C",hex($&))/ge;
    $KI{KeyprivateExponent} =~ s/(..)/pack("C",hex($&))/ge;
  }

### Create Certificate Data ##############################################
# TBSCertificate: X509version X509serial X509signature X509issuer X509validity X509subject X509subjectPublicKeyInfo (X509issuerUniqueID) (X509subjectUniqueID) X509extensions

#### Certificate Version #### (x509 v3)
  my $X509version = "a003020102";

#### Serial Number #### 
  my $X509serial=ASN1Wrap("02",DecToHex($context{'Serial'}));

#### Type of Signature #### Use SHA1 and RSA
  my $X509signature="300d06092a864886f70d0101050500"; #SEQ(OID:SHA1WithSHA1Encryption NULL)

#### Issuer (straight from certificate)
  my $X509issuer=( defined $CI{X509subject} ) ? Hex($CI{X509subject}) : $ASN1DN;

#### Validity ####
  my $X509Validity=ASN1Wrap("30",ASN1Wrap("17",Hex($beforeDate)).ASN1Wrap("17",Hex($afterDate)));

#### Subject ####
  my $X509subject=$ASN1DN;

#### Public Key (RSA) ####
  my $PubKeyChunk=ASN1Wrap("30",$Keymodulus.$KeypublicExponent);
  my $X509subjectPublicKeyInfo=ASN1Wrap("30",ASN1Wrap("30","06092a864886f70d0101010500").ASN1Wrap("03",ASN1BitStr($PubKeyChunk)));

#### Extensions ####

#KeyUsage;  Critical:Certificate Sign, CRL Sign  -OR- Critical:Dig sign & Key encypher & Key Agree
  my $keyusage=ASN1Wrap("30","0603551d0f"."0101ff".(($context{'CA'} eq "True")?"040403020106":"0404030203a8"));

#BasicConstraints;  Critical:CA=True & Pathlen undefiend  -OR-  Critical:CA=False & Pathlen undefiend
  my $basicconstraints=ASN1Wrap("30","0603551d13"."0101ff".(($context{'CA'} eq "True")?"040530030101ff":"04023000")); # why 04023000 not 04053003010100 (DER).

#SKID
#  my $PubKeyDigest=sha1_hex($PubKeyChunk); oops
  my $digestable=$PubKeyChunk;
  $digestable=~s/(..)/pack('C',hex($&))/ge;
  my $PubKeyDigest=sha1_hex($digestable);
  my $SKID=ASN1Wrap("30","0603551d0e".ASN1Wrap("04",ASN1Wrap("04",$PubKeyDigest)));

#AKID
  my $AKID;
  if ( ! defined $context{'CACert'} ) { 
    $CI{subjectKeyIdentifier} = $PubKeyDigest;
    $CI{X509issuer}           = $X509issuer;
    $CI{X509serial}           = $X509serial; 
    $CI{subjectKeyIdentifier} =~ s/(..)/pack("C",hex($&))/ge;
    $CI{X509issuer}           =~ s/(..)/pack("C",hex($&))/ge;
    $CI{X509serial}           =~ s/(..)/pack("C",hex($&))/ge;
  }

  $AKID=ASN1Wrap("30", "0603551d23".ASN1Wrap("04",ASN1Wrap("30",ASN1Wrap("80",Hex($CI{subjectKeyIdentifier}))
                                                               .ASN1Wrap("a1",ASN1Wrap("a4",Hex($CI{X509issuer})))
                                                               .ASN1Wrap("82",Hex(scalar ASN1Unwrap($CI{X509serial}))) )));

#Alternative names
if ( $SubjectAltName ne "" ) { $SubjectAltName = ASN1Wrap("30","0603551d11".$SubjectAltName) }
if ( $IssuerAltName  ne "" ) { $IssuerAltName  = ASN1Wrap("30","0603551d12".$IssuerAltName) }

#Concat and wrap the Extensions
  my $X509extensions=ASN1Wrap("a3",ASN1Wrap("30",$SKID.$AKID.$keyusage.$basicconstraints.$SubjectAltName.$IssuerAltName.$ExtraExts));

#### The whole chunck of certificate to be signed ####
  my $TBSCertificate=ASN1Wrap("30",$X509version.$X509serial.$X509signature.$X509issuer.$X509Validity.
                                   $X509subject.$X509subjectPublicKeyInfo.$X509extensions);

### Create Signature #################################################
# X509signatureAlgorithm X509signature

# Make MD5 Checksum and RSA sign it
  my $BinaryTBSCertificate = $TBSCertificate;
  $BinaryTBSCertificate   =~ s/(..)/pack('C',hex($&))/ge;
  my $RSAsignedDigest      = VOMS::Lite::CertKeyHelper::digestSign("sha1WithRSA",$BinaryTBSCertificate,Hex($KI{KeyprivateExponent}),Hex($KI{Keymodulus}));
  my $Signature            = ASN1Wrap("03",ASN1BitStr($RSAsignedDigest)); #(Always n*8 bits for MDnRSA and SHA1RSA)

### Wrap Certificate up with Signature ################################
# TBSCertificate X509signatureAlgorithm X509signature

  my $Certificate             = ASN1Wrap("30",$TBSCertificate.$X509signature.$Signature);

### Pack and return Certificate and Key in DER format #################

  $Certificate=~s/(..)/pack('C',hex($&))/ge;
  $Privatekey=~s/(..)/pack('C',hex($&))/ge;

  return { Cert=>$Certificate, Key=>$Privatekey, Warnings=>\@Warnings, Hash=>$Hash };
}

1;

__END__

=head1 NAME

VOMS::Lite::X509 - Perl extension for X509 Certificate creation and examination

=head1 SYNOPSIS

  use VOMS::Lite::X509;
  %X509=VOMS::Lite::X509::Create(
                                   { 
                                     Serial=>0, 
                                     DN=>["C=GB","CN=my common name"],
                                   } 
                                );
  my $DER=$X509{'Cert'};
  %CertInfo= %{ 
                VOMS::Lite::X509::Examine( $DER, 
                                           { 
                                             SubjectDN=>"",
                                             IssuerDN=>""
                                           } 
                                         ) 
              }; 
  print "$CertInfo{'SubjectDN'}\n$CertInfo{'IssuerDN'}\n";

=head1 DESCRIPTION

VOMS::Lite::X509 provides a library to create and to examine X509 cerificates.

=head2 VOMS::Lite::X509::Create

VOMS::Lite::X509::Create takes one argument, an anonymous hash 
containing all the relevant information required to make the 
X509 Certificate.

  In the Hash the following scalars should be defined:
  'Serial' the decimal value of the serial number for the certificate
  'DN'     the array of attribute=value strings that make up the 
     Distinguished Name

  Both or neither of these should be defined:
  'CACert' the DER encoding of the issuing (CA) certificate.
  'CAKey'  the DER encoding of the issuing (CA) key.

  The following are optional:
    'Lifetime' the lifetime of the credential to be issued in seconds
    'CA'       can be either 'True' or 'False' if defined 
               (it sets the basic constraints and key usage values)
    'Bits'     the size of the key can be any of 512,1024,2048,4096
    'Extensions' a reference to an array of strings containing 
               X509 extensions i.e. an array of DER encoded: 
               SEQUENCE ::= { OID, 
                              extnID OBJECT IDENTIFIER, 
                              critical BOOLEAN DEFAULT FALSE, 
                              extnValue OCTET STRING  }

    'subjectAltName' a reference to an Array of Generalnames e.g.
              [ 'rfc822Name=mike.jones@manchester.ac.uk',
                'dNSName=a.dns.fqdn',
                'directoryName=300f310d300b060355040313044d696b65', 
                   # The hex can also be specified as unsigned chars
                'uniformResourceIdentifier=http://www.mc.manchester.ac.uk/projects/shebangs/',
                'IPAddress=\202\130\001\202\377\377\377\377' ]

The return value is a hash reference containing the X509 Certificate and Key 
strings in DER format (Cert and Key), a reference to an array of 
'Warnings' (a certificate will still be created if warnings are present),
a reference to an array of 'Errors' (if an error is encountered then no 
Proxy will be produced), and a string 'Hash' of the openssl-type for the 
produced certificate's name.

=head2 VOMS::Lite::X509::Examine

VOMS::Lite::X509::Examine takes two arguments: the DER encoded X509 certificate and a hash of the required information.
If defined in the hash of the first element in the call to Examine
the following variables will be parsed from the certificate and
returned in the return referenced hash.
  Chuncks of DER encoded data directly from the certificate:
  'X509version'               - DER encoded version
  'X509serial'                - DER encoded serial number
  'X509signature'             - DER encoded siganture type
  'X509issuer'                - DER encoded issuer
  'X509validity'              - DER encoded validity
  'X509subject'               - DER encoded subject
  'X509subjectPublicKeyInfo'  - DER encoded subject Public Key Info
  'X509issuerUniqueID'        - DER encoded Issuer Unique ID
  'X509subjectUniqueID'       - DER encoded Subject Unique ID
  'X509extensions'            - DER encoded Extensions

  'Start'                     - Valid from value of the certificate
                                (seconds since midnight 1 Jan 1970)
  'End'                       - Valid until value of the certificate
                                (seconds since midnight 1 Jan 1970)
  'SubjectDN'                 - Subject's DN string, slash seperated
                                representation (yuk)
  'IssuerDN'                  - Issuer's DN string, slash seperated
                                representation (yuk)

  'subjectKeyIdentifier'      - byte string representing the Subject
                                Key Identifier extension
  'authorityKeyIdentifier'    - DER encoded Authority Key Identifier
                                extension, if set the folloring
                                binary values will also be returned:
    'authorityKeyIdentifierSkid'    - Authority's Subject Key
                                      Identifier (byte string)
    'authorityKeyIdentifierIssuer'  - Authority's General Name DER
                                      encoded
    'authorityKeyIdentifierSerial'  - Authority's Serial Number as a
                                      hex string.
  'keyUsage'                  - The Packed keyUsage extension value,
                                if set the folloring binary values
                                will also be returned:
    'keyUsageDigitalSignature'    0=false, 1=true
    'keyUsageNonRepudiation'      0=false, 1=true
    'keyUsageKeyEncipherment'     0=false, 1=true
    'keyUsageDataEncipherment'    0=false, 1=true
    'keyUsageKeyAgreement'        0=false, 1=true
    'keyUsageKeyCertSign'         0=false, 1=true
    'keyUsageCRLSign'             0=false, 1=true
    'keyUsageEncipherOnly'        0=false, 1=true
    'keyUsageDecipherOnly'        0=false, 1=true
  'basicConstraints'          - The Packed keyUsage extension value,
                                if set the folloring binary values
                                will also be returned:
    'basicConstraintsCA'          0=false, 1=true
    'basicConstraintsPathLen'     path length integer

=head2 EXPORT

None;  

=head1 SEE ALSO

RFC3820

This module was originally designed for the SHEBANGS project at The University of Manchester.
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
