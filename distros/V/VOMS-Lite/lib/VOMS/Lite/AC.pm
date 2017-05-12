package VOMS::Lite::AC;

use 5.004;
use strict;
use Time::Local;
use VOMS::Lite::ASN1Helper qw(ASN1Unwrap ASN1OIDtoOID Hex DecToHex ASN1BitStr ASN1Wrap ASN1Index);
use VOMS::Lite::CertKeyHelper qw(digestSign buildchain);
use VOMS::Lite::PEMHelper qw(readCert);
use VOMS::Lite::X509;
use VOMS::Lite::KEY;
use Sys::Hostname;
#use Regexp::Common qw (URI);

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

$VERSION = '0.20';

#############################################
sub Examine {
  my ($decoded,$dataref)=@_;
  $dataref={Start=>"",End=>"",FQANs=>"",IssuerDN=>"",HolderIssuerDN=>"",VOMSDIR=>"/etc/grid-security/vomsdir"} if( ! defined $dataref );
  my %Values=%$dataref;
  my @ASN1Index=ASN1Index($decoded);
  my @Values;
  return ( {Errors=>"Unable to parse attribute certificate"} ) if (@ASN1Index==0);

  my ($index,$ignoreuntil)=(0,0);

# Drill down into the certificate
  shift @ASN1Index; # skip the wrapping of the attribute certificate sequence 
  shift @ASN1Index; # skip the wrapping of the bundle of atribute certificate sequence

# Get each AC  
  my @ACs;
  foreach (@ASN1Index) {
    my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @$_;
    if ( $HEADSTART < $ignoreuntil ) { next; }
    else {
      push @ACs,[$CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN];
      $ignoreuntil=$HEADSTART+$HEADLEN+$CHUNKLEN;
    }
  }

  foreach (@ACs) {
    my %LocalValues;
    my ($ACversion,$ACholder,$ACissuer,$ACalgorithmId,$ACSerial,$ACvalidity,$ACattribute,$ACUniqueId,$ACExtensions,$ACSignatureType,$ACSignature);
    my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN)=@$_;
    my ($TBSAC,$SIGType,$SIG);
    $ignoreuntil=$HEADSTART+$HEADLEN;
    my $ignoreafter=$HEADSTART+$HEADLEN+$CHUNKLEN;
    my $index=0;
    my $SIGSTART;
    foreach (@ASN1Index) {
      my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @$_;
      if ( $HEADSTART < $ignoreuntil ) { next; }
      elsif ( $HEADSTART >= $ignoreafter ) { last; }
      else {
        if    ($index==0) { $TBSAC         = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN)); $index++; $SIGSTART=$HEADSTART+$HEADLEN+$CHUNKLEN; next;} #this is a container
        elsif ($index==1) { $ACversion     = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
        elsif ($index==2) { $ACholder      = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
        elsif ($index==3) { $ACissuer      = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
        elsif ($index==4) { $ACalgorithmId = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
        elsif ($index==5) { $ACSerial      = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
        elsif ($index==6) { $ACvalidity    = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));;}
        elsif ($index==7) { $ACattribute   = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
        elsif ($index==8 && $HEADSTART < $SIGSTART) { $ACExtensions  = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
        elsif ($index==8) {$index++; next;}
        elsif ($index==9) { $ACSignatureType = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
        elsif ($index==10){ $ACSignature   = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN)); last;}
        $index++;
        $ignoreuntil=$HEADSTART+$HEADLEN+$CHUNKLEN;
      }
    }
# Extract the main components of the Attribute Certificate

#Standard
    if (defined $Values{TBSAC})           {$LocalValues{TBSAC}=$TBSAC;}
    if (defined $Values{ACversion})       {$LocalValues{ACversion}=$ACversion;}
    if (defined $Values{ACholder})        {$LocalValues{ACholder}=$ACholder;}
    if (defined $Values{ACissuer})        {$LocalValues{ACissuer}=$ACissuer;}
    if (defined $Values{ACalgorithmId})   {$LocalValues{ACalgorithmId}=$ACalgorithmId;}
    if (defined $Values{ACSerial})        {$LocalValues{ACSerial}=$ACSerial;}
    if (defined $Values{ACvalidity})      {$LocalValues{ACvalidity}=$ACvalidity;}
    if (defined $Values{ACattribute})     {$LocalValues{ACattribute}=$ACattribute;}
    if (defined $Values{ACExtensions})    {$LocalValues{ACExtensions}=$ACExtensions;}
    if (defined $Values{ACSignatureType}) {$LocalValues{ACSignatureType}=$ACSignatureType;}
    if (defined $Values{ACSignature})     {$LocalValues{ACSignature}=$ACSignature;}

    if ($ACExtensions ne "" ) { 
      my @ACExtensionIndex=ASN1Index($ACExtensions);
      shift @ACExtensionIndex; #Unwrap extensions;
      while (@ACExtensionIndex) {
        my $Seqref=shift(@ACExtensionIndex);
        my $OIDref=shift(@ACExtensionIndex);
        my $OSref=shift(@ACExtensionIndex);
        my $Critical=( $OSref =~ /\x01\x01[^\0]/ )?1:0;
        $OSref=shift(@ACExtensionIndex) if ($Critical);
        my $OID=substr($ACExtensions,(${ $OIDref }[3]+${ $OIDref }[4]),${ $OIDref }[5]);
        my $OIDstr=ASN1OIDtoOID($OID);
        if($OIDstr eq "2.5.29.56" && defined $Values{'noRevAvail'}) { 
          $LocalValues{noRevAvail} = "\x01"; 
        } 
        if($OIDstr eq "2.5.29.35" && defined $Values{'authorityKeyIdentifier'}) {  
          my $AKI=substr($ACExtensions,(${ $OSref }[3]+${ $OSref }[4]),${ $OSref }[5]);
          $AKI=ASN1Unwrap($AKI);
          $LocalValues{authorityKeyIdentifier}=$AKI;
          $LocalValues{authorityKeyIdentifierSkid}   = undef;   #explicitly undefine these incase they were set in the call!
          $LocalValues{authorityKeyIdentifierIssuer} = undef; #
          $LocalValues{authorityKeyIdentifierSerial} = undef; #
          until (length($AKI) == 0) {
            my ($headlen,$reallen,$Class,$Constructed,$Tag,$str)=ASN1Unwrap($AKI);
            $AKI=substr($AKI,($headlen+$reallen));
            if    ($Tag==0) {$LocalValues{authorityKeyIdentifierSkid}=$str;}
            elsif ($Tag==1) {$LocalValues{authorityKeyIdentifierIssuer}=$str;}
            elsif ($Tag==2) {$LocalValues{authorityKeyIdentifierSerial}=Hex($str);}
          }
        } 
        if($OIDstr eq "1.3.6.1.4.1.8005.100.100.11" && defined $Values{'vOMSTags'} ) {
          $LocalValues{vOMSTags}=substr($ACExtensions,(${ $OSref }[3]+${ $OSref }[4]),${ $OSref }[5]); 
        } 
        if($OIDstr eq "1.3.6.1.4.1.8005.100.100.10" && ( defined $Values{'vOMSACCertList'} || defined $Values{Verify} ) ) {
          my $SEQ=ASN1Unwrap(substr($ACExtensions,(${ $OSref }[3]+${ $OSref }[4]),${ $OSref }[5]));
          my @DERs;
          until (length($SEQ) == 0) {
            my ($headlen,$reallen,$Class,$Constructed,$Tag,$cert)=ASN1Unwrap($SEQ);
            $SEQ=substr($SEQ,($headlen+$reallen));
            push @DERs,$cert;
          }
          $LocalValues{vOMSACCertList} = \@DERs;
        } 
      }  
    }

#Deep
    if (defined $Values{Version} ) {
      $LocalValues{Version} = ASN1Unwrap($ACversion);
    }

#To whom does the AC belong
    if ( defined $Values{HolderIssuerDN} || defined $Values{HolderSerial} ) {
      $Values{HolderSerial}=""; $Values{HolderIssuerDN}=""; # one doesn't make sense without the other makesure both are set
      my $a0=ASN1Unwrap($ACholder);
      my $SEQ=ASN1Unwrap($a0);
      my ($headlen,$reallen,$Class,$Constructed,$Tag,$name)=ASN1Unwrap($SEQ);
      my $int=ASN1Unwrap(substr($SEQ,($headlen+$reallen)));
      $SEQ=ASN1Unwrap($name);
      my @rdns=ASN1Index($SEQ);
      while (@rdns) {
        my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN)=(0,0,0,0,0);
        until ($TAG == 6 ) { ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @rdns}; }
        my $OID=substr($SEQ,($HEADSTART+$HEADLEN),$CHUNKLEN);
        ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @rdns};
        my $Value=substr($SEQ,($HEADSTART+$HEADLEN),$CHUNKLEN);
        $LocalValues{HolderIssuerDN}.="/".VOMS::Lite::CertKeyHelper::OIDtoDNattrib(ASN1OIDtoOID($OID))."=$Value";
      }
      $LocalValues{HolderSerial} = "0x".Hex($int);
    }

# Who was the Issuer
    if ( defined $Values{IssuerDN} || defined $Values{Verify}) {
      my $SEQ=ASN1Unwrap($ACissuer);
      my $name=ASN1Unwrap($SEQ);
      $SEQ=ASN1Unwrap($name);
      my @rdns=ASN1Index($SEQ);
      while (@rdns) {
        my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN)=(0,0,0,0,0);
        until ($TAG == 6 ) { ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @rdns}; }
        my $OID=substr($SEQ,($HEADSTART+$HEADLEN),$CHUNKLEN);
        ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @rdns};
        my $Value=substr($SEQ,($HEADSTART+$HEADLEN),$CHUNKLEN);
        $LocalValues{IssuerDN}.="/".VOMS::Lite::CertKeyHelper::OIDtoDNattrib(ASN1OIDtoOID($OID))."=$Value";
      }
    }

# What was/were the Attribute(s)
  if ( defined $Values{PA} || defined $Values{FQANs} ) {
    my @AttrIndex=ASN1Index($ACattribute);
    my @Attrs;
    my $PA;
      my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN)=(0,0,-1,0,0);
      until ($CLASS==2 && $TAG == 6 ) { ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @AttrIndex}; }
      $PA=substr($ACattribute,($HEADSTART+$HEADLEN),$CHUNKLEN);
    while (@AttrIndex) {
      my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN)=(0,0,-1,0,0);
      until ($CLASS==0 && $TAG == 4 ) { ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @AttrIndex}; }
      my $Value=substr($ACattribute,($HEADSTART+$HEADLEN),$CHUNKLEN);
      push @Attrs,$Value;
    }
    $LocalValues{PA}=$PA;
    $LocalValues{FQANs}=\@Attrs;
  }

# Values of Start and End Time Seconds since Epoch
    if (defined $Values{Start} || defined $Values{End}) {
      my @validity=ASN1Unwrap($ACvalidity);
      my @st=ASN1Unwrap($validity[5]);
      my @et=ASN1Unwrap(substr($validity[5],$st[0]+$st[1]));
      if    ( $st[4] eq "23" && $st[5]=~ /^(..)(..)(..)(..)(..)(..)Z$/ )   { $LocalValues{Start} = timegm($6,$5,$4,$3,($2-1),$1); }
      elsif ( $st[4] eq "24" && $st[5]=~ /^(....)(..)(..)(..)(..)(..)Z$/ ) { $LocalValues{Start} = timegm($6,$5,$4,$3,($2-1),$1); }
      if    ( $et[4] eq "23" && $et[5]=~ /^(..)(..)(..)(..)(..)(..)Z$/ )   { $LocalValues{End}   = timegm($6,$5,$4,$3,($2-1),$1); }
      elsif ( $et[4] eq "24" && $et[5]=~ /^(....)(..)(..)(..)(..)(..)Z$/ ) { $LocalValues{End}   = timegm($6,$5,$4,$3,($2-1),$1); }
    }

# Signature Value
    if (defined $Values{SignatureValue} || defined $Values{SignatureType} || defined $Values{Verify}) {
      $LocalValues{'EncSignatureValue'}=Hex(substr(ASN1Unwrap($ACSignature),1));
      my $HexACSignature=Hex($ACSignatureType);
      if    ( $HexACSignature eq "300d06092a864886f70d0101040500" ) { $LocalValues{'SignatureType'}="md5WithRSA"; }
      elsif ( $HexACSignature eq "300d06092a864886f70d0101050500" ) { $LocalValues{'SignatureType'}="sha1WithRSA"; }
      elsif ( $HexACSignature eq "300d06092a864886f70d0101030500" ) { $LocalValues{'SignatureType'}="md4WithRSA"; }
      elsif ( $HexACSignature eq "300d06092a864886f70d0101020500" ) { $LocalValues{'SignatureType'}="md2WithRSA"; }
      else  { $LocalValues{'SignatureType'}="unrecognised"; }
    }

# Verify it
    if (defined $Values{Verify}) {
       my @ACIssuers;
       if ( ! defined $Values{'VOMSDIR'} ) { $Values{'VOMSDIR'}="/etc/grid-security/vomsdir"; }
       if ( -d $Values{'VOMSDIR'} ) {
         opendir(my $dh, $Values{'VOMSDIR'});
         @ACIssuers = grep { /^[^.]/ && -f "$Values{VOMSDIR}/$_" } readdir($dh);
         closedir $dh;
       }
       $LocalValues{Verify}=0;

       for (my $II=-1;$II<@ACIssuers;$II++) {
          $Values{'IssuerDN'}="";  # set Issuer DN to be exported
          $Values{'InternalVOMSCert'}=""; # set indicator of VOMS cert attached
          my @decodedCERTS;
          if ( $II == -1 ) { # 1st time round try attached certs. Assuming the certlist is a chain not a list of possible issuers
            next if ( ! defined $LocalValues{vOMSACCertList} );
            @decodedCERTS=@{ $LocalValues{vOMSACCertList} }; 
            $LocalValues{'InternalVOMSCert'} = "Attached";
          }
          else { 
            @decodedCERTS=readCert($Values{'VOMSDIR'}."/$ACIssuers[$II]"); 
            $LocalValues{'InternalVOMSCert'} = "Local";
          }

          my %Chain = %{ buildchain( { trustedCAdirs => ["/etc/grid-security/certificates"], ####Can this be an option?
                                       suppliedcerts => \@decodedCERTS, 
                                       trustedCAs    => [] } ) };

          next if ( @{ shift @{ $Chain{Errors} } } );
          next if (! ${ $Chain{TrustedCA} }[-1] ); 
          next if ( $Chain{'EndEntityDN'} ne $LocalValues{'IssuerDN'} );
          my $X509REF=VOMS::Lite::X509::Examine($Chain{EndEntityCert},{Keymodulus=>"",KeypublicExponent=>""});
          if (VOMS::Lite::CertKeyHelper::verifySignature(
                                                          $LocalValues{'SignatureType'},
                                                          $LocalValues{'EncSignatureValue'},
                                                          $TBSAC,
                                                          Hex(${ $X509REF }{'KeypublicExponent'}),
                                                          Hex(${ $X509REF }{'Keymodulus'}))) {
            $LocalValues{'Verify'} = 1 ; last;
          }
       }
    }

    push @Values,{};
    foreach (keys %Values) { ${ $Values[-1] }{$_}=$LocalValues{$_}; }
  }

  return @Values;
}


###############################

sub Create {
  my $inputref = shift;
  my %context  = %{$inputref};
  my @error=();
  my @warning=();
  my $AC;

# Check for values which need to be defined
  if ( ! defined $context{'Cert'} )     { push @error,   "VOMS::Lite::AC: Holder certificate not supplied"; }
  if ( ! defined $context{'VOMSCert'} ) { push @error,   "VOMS::Lite::AC: VOMS certificate not supplied"; }
  if ( ! defined $context{'VOMSKey'} )  { push @error,   "VOMS::Lite::AC: VOMS key not supplied"; }
  if ( ! defined $context{'Lifetime'} ) { push @error,   "VOMS::Lite::AC: VOMS AC Lifetime not supplied"; }
  if ( ! defined $context{'Server'} )   { push @error,   "VOMS::Lite::AC: VOMS Server FQDN not supplied"; }
  if ( ! defined $context{'Port'} )     { push @error,   "VOMS::Lite::AC: VOMS Server Port not supplied"; }
  if ( ! defined $context{'Serial'} )   { push @error,   "VOMS::Lite::AC: VOMS AC Serial not supplied"; }
  if ( ! defined $context{'Code'} )     { push @warning, "VOMS::Lite::AC: Code not supplied, using Port Value"; }
  if ( ! defined $context{'Attribs'} )  { push @error,   "VOMS::Lite::AC: VOMS Attributes not supplied"; }

# Bail if there isn't enough information
  if ( @error > 0 ) { return { Errors => \@error} ; }

# Load input data into local variables
  my $CertInfoRef  = (($context{'Cert'}     =~ /^(\060.*)$/s) ? VOMS::Lite::X509::Examine($&, {X509issuer=>"", X509serial=>"", X509subject=>""}) : undef);
  my $VCertInfoRef = (($context{'VOMSCert'} =~ /^(\060.+)$/s) ? VOMS::Lite::X509::Examine($&, {X509issuer=>"", subjectKeyIdentifier=>"", X509subject=>""}) : undef);
  my $VKeyInfoRef  = (($context{'VOMSKey'}  =~ /^(\060.+)$/s) ?  VOMS::Lite::KEY::Examine($&, {Keymodulus=>"", KeyprivateExponent=>""}) : undef);
  my %CERTINFO;  if ( defined $CertInfoRef )   { %CERTINFO=%$CertInfoRef; }   else { push @error,   "VOMS::Lite::AC: Unable to parse holder certificate."; }
  my %VCERTINFO; if ( defined $VCertInfoRef )  { %VCERTINFO=%$VCertInfoRef; } else { push @error,   "VOMS::Lite::AC: Unable to parse VOMS certificate."; }
  my %VKEYINFO;  if ( defined $VKeyInfoRef )   { %VKEYINFO=%$VKeyInfoRef; }   else { push @error,   "VOMS::Lite::AC: Unable to parse VOMS key."; }
  if ( @error > 0 ) { return { Errors => \@error} ; }

  my $Lifetime     = (($context{'Lifetime'} =~ /^([0-9]+)$/)       ? $& : undef);
  my $Server       = (($context{'Server'}   =~ /^([a-z0-9_.-]+)$/) ? $& : undef);
  my $Port         = (($context{'Port'}     =~ /^([0-9]{1,5})$/ && $context{'Port'} < 65536) ? $& : undef);
  my $Serial       = (($context{'Serial'}   =~ /^([0-9a-f]+)$/)    ? $& : undef);
  my $Code         = (($context{'Code'}     =~ /^([0-9]+)$/)       ? $& : undef);
  my $AttribRef    = $context{'Attribs'};
  my $Broken       = $context{'Broken'};

# Get the attributes from the supplied reference
  my @Attribs=();
  foreach ( @$AttribRef ) {
    my ($cap,$rl);
    if ( /(\/Capability=[\w.-]+)$/ )   { $cap = $1; }
    if ( /(\/Role=[\w.-]+)$cap$/ )     { $rl = $1; }
    if ( /^((?:\/[\w.-]+)+$rl$cap)$/ ) { push @Attribs,$&; }
  }

# Get any targets from the supplied reference
  my @Targets=();
  if (defined $context{'Targets'} && $context{'Targets'} =~ /^ARRAY/ ) {
    foreach ( @{ $context{'Targets'} } ) {
      if (/^([a-zA-Z0-9()'*~!._;\/?:\@&=+\$,#-]|%[a-fA-F0-9]{2})+$/) { push @Targets, $1; }
#      if (/^($RE{URI})$/) { push @Targets, $1;}   --- Regexp: a sledge hammer -- we shouldn't be so prescriptive
      else { push @error, "VOMS::Lite::AC: At least 1 target was an invalid URI (see eg RFC2396)";}
    }
  }

# Check for errors in local variables
  if ( ! defined $Lifetime )                        { push @error, "VOMS::Lite::AC: Invalid Lifetime"; }
  if ( ! defined $Server )                          { push @error, "VOMS::Lite::AC: Invalid Server"; }
  if ( ! defined $Port )                            { push @error, "VOMS::Lite::AC: Invalid Port"; }
  if ( ! defined $Serial )                          { push @error, "VOMS::Lite::AC: Invalid Serial Number"; }
  if ( ! defined $Code )                            { $Code = $Port; }
  if ( ! defined $CERTINFO{X509issuer} )            { push @error, "VOMS::Lite::AC: Unable to get holder certificate's issuer"; }
  if ( ! defined $CERTINFO{X509serial} )            { push @error, "VOMS::Lite::AC: Unable to get holder certificate's serial"; }
  if ( ! defined $CERTINFO{X509subject} )           { push @error, "VOMS::Lite::AC: Unable to get holder certificate's subject"; }
  if ( ! defined $VCERTINFO{X509issuer} )           { push @error, "VOMS::Lite::AC: Unable to get VOMS certificate's issuer"; }
  if ( ! defined $VCERTINFO{subjectKeyIdentifier} ) { push @error, "VOMS::Lite::AC: Unable to get VOMS certificate's Subject Key Identifier"; }
  if ( ! defined $VCERTINFO{X509subject} )          { push @error, "VOMS::Lite::AC: Unable to get VOMS certificate's subject"; }
  if ( ! defined $VKEYINFO{Keymodulus} )            { push @error, "VOMS::Lite::AC: Unable to get VOMS key's Modulus"; }
  if ( ! defined $VKEYINFO{KeyprivateExponent} )    { push @error, "VOMS::Lite::AC: Unable to get VOMS key's Exponent"; }
  if ( $#Attribs < 0 )                              { push @error, "VOMS::Lite::AC: No Attributes supplied"; }

# Bail if any required variable failed to load 
  if ( @error > 0 ) { return {  Targets => \@Targets, Attribs => \@Attribs, Warnings => \@warning, Errors => \@error }; }

# Pad serial number
  $Serial =~ s/^.(..)*$/0$&/;

# The Identity of this VOMS from first part of first Attribute
  my $Group=(($Attribs[0] =~ /^\/?([^\/]+)/) ? $1 : undef);
  if ( ! defined $Group )    { push @error,   "VOMS::Lite::AC: VOMS Group not defined"; }
  if ( @error > 0 ) { return {  Targets => \@Targets, Attribs => \@Attribs, Warnings => \@warning, Errors => \@error }; }
  my $VOMSURI=$Group."://".$Server.":".$Port;

# Get times Now and Now + N hours
  my $NOW=time();
  my @NOW=gmtime($NOW);
  my @FUT=gmtime($NOW+$Lifetime);
  my $NotBeforeDate = sprintf("%04i%02i%02i%02i%02i%02iZ",($NOW[5]+1900),($NOW[4]+1),$NOW[3],$NOW[2],$NOW[1],$NOW[0]);
  my $NotAfterDate  = sprintf("%04i%02i%02i%02i%02i%02iZ",($FUT[5]+1900),($FUT[4]+1),$FUT[3],$FUT[2],$FUT[1],$FUT[0]);

###########################################################
# OK Let's create a VOMS Attribute Certificate!  This consists of:  
# AttCertVersion Holder AttCertIssuer AlgorithmIdentifier CertificateSerialNumber
# AttCertValidityPeriod AttributeSequence UniqueIdentifier Extensions

# Version (=2 (i.e. 01))
  my $AttCertVersion="020101";

# Holder of Attribute.  This this is a sequence containing the holder certificate's issuer DN and serial. 
  my $HolderIssuer            = Hex( ( defined $Broken && $Broken ) ? $CERTINFO{X509subject}:$CERTINFO{X509issuer} );
  my $HolderSerial            = Hex( $CERTINFO{X509serial} );
  my $HolderInfo              = ASN1Wrap( "30",ASN1Wrap( "a4",$HolderIssuer ) ).$HolderSerial;
  my $Holder                  = ASN1Wrap( "30",ASN1Wrap( "a0",$HolderInfo ) );

# Issuer of Attribute Certificate
  my $AttCertIssuerInfo       = Hex($VCERTINFO{X509subject});
  my $AttCertIssuer           = ASN1Wrap("a0",ASN1Wrap("30",ASN1Wrap("a4",$AttCertIssuerInfo)));

# Signing Algorythm used in this Attribute Certificate
  my $AlgorithmIdentifier     = "300d06092a864886f70d0101040500";

# Serial Number
  my $SN                      = $Serial.DecToHex($Code);
  if ( length($SN) > 80 ) { 
    push @warning, "AC: The size of the serial number is too large, using truncated version.";
    $SN                       = substr($SN,-40);
  }
  my $CertificateSerialNumber = ASN1Wrap("02",$SN);

# Attribute Certificate validity period 
  my $AttCertValidityPeriod   = ASN1Wrap("30",ASN1Wrap("18",Hex($NotBeforeDate)).ASN1Wrap("18",Hex($NotAfterDate)));

# Attributes from Attrib array supplied and VOMS URI (from group, server and port)
  my $VOMSOIDChunck           = "060a2b06010401be45646404";  # OID, encoded-length=10, 1.3.6.1.4.1.8005.100.100.4
  my $VOMSURIChunck           = ASN1Wrap("a0",ASN1Wrap("86",Hex("$VOMSURI")));
  my $VOMSTripleChunck        = "";
  my $VT="";
  foreach (@Attribs) { $VT   .= ASN1Wrap("04",Hex($_)); }   # Concatination of wrapped Attributes
  $VOMSTripleChunck           = ASN1Wrap("30",$VT);
  my $VOMSAttribChunck        = ASN1Wrap("31",ASN1Wrap("30",$VOMSURIChunck.$VOMSTripleChunck));
  my $AttributeSequence       = ASN1Wrap("30",ASN1Wrap("30",$VOMSOIDChunck.$VOMSAttribChunck));

#Unique Identifier
  my $UniqueIdentifier="";   # Optional and we do not specify it here

#Extensions
  #Targets
  my $ACTargets="";
  my $targetInformation="";
  foreach my $uniformResourceIdentifier (@Targets) {
    $ACTargets.=ASN1Wrap("30",ASN1Wrap("a0",ASN1Wrap("a0",ASN1Wrap("86",$uniformResourceIdentifier))));
  }
  if ($ACTargets ne "") { $targetInformation=ASN1Wrap("30","0603551d37". # OID 2.5.29.55
                                                       "0101ff".          # Critical
                                                       ASN1Wrap("04",ASN1Wrap("30",$ACTargets)));}
  #Issuer Certs
#  my $IssuerCerts="";
  my $IssuerCerts=ASN1Wrap("30","060a2b06010401be4564640a".ASN1Wrap("04",ASN1Wrap("30",ASN1Wrap("30",Hex($context{'VOMSCert'})))));
  #NoRevocation
  my $NoRevAvail = "30090603551d3804020500";   # OID 2.5.29.56 + contents=Null
  #Issuer Unique ID
  my $IssuerUniqueID=ASN1Wrap("30","0603551d23".ASN1Wrap("04",ASN1Wrap("30",ASN1Wrap("80",Hex($VCERTINFO{subjectKeyIdentifier})))));
  #Tags
  my $Tag="";

  my $Extensions=ASN1Wrap("30",$targetInformation.$IssuerCerts.$NoRevAvail.$IssuerUniqueID.$Tag);

# Concatinate and wrap into a ToBeSignedAttributeCertificate
  my $UnsignedAC              = ASN1Wrap("30",$AttCertVersion.
                                               $Holder.
                                               $AttCertIssuer.
                                               $AlgorithmIdentifier.
                                               $CertificateSerialNumber.
                                               $AttCertValidityPeriod.
                                               $AttributeSequence.
                                               $UniqueIdentifier.
                                               $Extensions);

###########################################################
# Make MD5 Checksum
  my $BinaryUnsignedAC        = $UnsignedAC;
  $BinaryUnsignedAC          =~ s/(..)/pack('C',hex($&))/ge;

# Make MD5 signature and rsa sign it
  my $RSAsignedDigest         = digestSign("md5WithRSA",$BinaryUnsignedAC,Hex($VKEYINFO{KeyprivateExponent}),Hex($VKEYINFO{Keymodulus}));

  my $ACSignature             = ASN1Wrap("03",ASN1BitStr($RSAsignedDigest)); #(Always n*8 bits for MDnRSA and SHA1RSA)

# Wrap it all up
#  $AC=ASN1Wrap("30",ASN1Wrap("30",ASN1Wrap("30",$UnsignedAC.$AlgorithmIdentifier.$ACSignature)));
  $AC=ASN1Wrap("30",$UnsignedAC.$AlgorithmIdentifier.$ACSignature);
  $AC=~s/(..)/pack('C',hex($&))/ge;

  return { AC => $AC, Targets => \@Targets, Attribs => \@Attribs, Warnings => \@warning };
}

1;
__END__

=head1 NAME

VOMS::Lite::AC - Perl extension for VOMS Attribute certificate creation

=head1 SYNOPSIS

  use VOMS::Lite::AC;
  %AC = %{ VOMS::Lite::AC::Create(%inputref) };
  
=head1 DESCRIPTION

VOMS::Lite::AC is primarily for internal use.

VOMS::Lite::AC::Create takes one argument, a hash containing all the relevant information required to make the 
Attribute Certificate.  
  In the Hash the following scalars should be defined:
  'Cert'     the DER encoding of the holder certificate.
  'VOMSCert' the DER encoding of the VOMS issuing certificate.
  'VOMSKey'  the DER encoding of the VOMS issuing key.
  'Lifetime' the integer lifetime of the credential to be issued in seconds
  'Server'   the FQDN of the VOMS server
  'Port'     the port of the VOMS server (between 0 and 65536) 
  'Serial'   the valus foe the serial number of the credential
  'Code'     optional, the VOMS code (if undefined will use the port and issue a warning)
  'Broken'   optional, define this to make AC issue broken backward compatable gLite 1 VOMS ACs.
  In vector context
  'Attribs'  the reference to the array of VOMS attribute triples
  'Targets'   optional, reference to an array of Target URIs

The return value is a reference to a hash containing the AC as a string in DER format,
a reference to an array of any Target URIs emposed,
a reference to an array of warnings (an AC will still be issued if warnings are present),
a reference to an array of errors (if an error is encountered then no AC will be produced).

=head2 EXPORT

None by default;  

=head1 SEE ALSO

RFC3281 and the VOMS Attribute Specification document from the OGSA Athuz Working Group of the Open Grid Forum http://www.ogf.org.  
Also see gLite from the EGEE.

This module was originally designed for the SHEBANGS project at The University of Manchester.
http://www.rcs.manchester.ac.uk/research/shebangs/

Mailing list, shebangs@listserv.manchester.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2009 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
