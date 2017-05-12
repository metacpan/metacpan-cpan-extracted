package VOMS::Lite::VOMS;

#Use/require here
use VOMS::Lite::ASN1Helper qw(DecToHex Hex ASN1Wrap ASN1Index ASN1OIDtoOID);
use IO::Socket;
use VOMS::Lite::X509;
use VOMS::Lite::CertKeyHelper qw(buildchain);
use VOMS::Lite::PEMHelper qw(readCert writeCert writeKey readPrivateKey encodeAC);
use VOMS::Lite::RSAHelper qw(rsaencrypt rsasign rsadecrypt rsaverify);
use VOMS::Lite::Base64;
use VOMS::Lite::AC;

use Digest::MD5 qw(md5_hex md5);
use Digest::SHA1 qw(sha1_hex sha1);
use Crypt::CBC;

require Exporter;
use vars qw($VERSION $DEBUG @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
$VERSION = '0.20';

BEGIN {
  $DEBUG='no';
}

my $CAdir="/etc/grid-security/certificates";
my $maxrecordsize=16384;
#sub ContMesg { return sprintf("%08s",DecToHex(length($_[0])/2)); } # returns hex continuation message for hexstring
sub Bin { return pack("H*", $_[0]); }
sub handShake { return $_[0].sprintf("%06s",DecToHex(length($_[1])/2)).$_[1]; }
sub Seq { return sprintf("%016s",DecToHex($_[0])); }
sub recordLayer { 
  my $rsz=$maxrecordsize*2; my $rs;
  my $len=length($_[1]);
  for (my $i=0;($i<$len) and $f=substr($_[1],$i,$rsz);$i+=$rsz) { $rs.=$_[0]."0300".sprintf("%04s",DecToHex(length($f)/2)).$f; } 
  return $rs; 
}
my ($pad1md5,$pad2md5,$pad1sha,$pad2sha) = ("\x36" x 48,"\x5c" x 48,"\x36" x 40,"\x5c" x 40);
sub MAC { my ($MS,$D)=@_; return md5_hex($MS.$pad2md5.md5($D.$MS.$pad1md5)).sha1_hex($MS.$pad2sha.sha1($D.$MS.$pad1sha));}
sub debug {
  return if ( $DEBUG ne "yes" );
  my ($type,$out,$hex) = @_;
  if ( $out eq "" ) { $out="$type\n"; }
  elsif ( $out =~ /^[\n -~]*$/ and ! defined($hex) ) { $out =~ s/(\n?)([^\n]{1,60})/$type.=(($1 eq "\n")?" +":"");printf("%-19s %s\n",$type,$2);$type=""/ges; }
  else                            { $out =~ s/(.{1,16})/$a=Hex($1), $a=~s|..|$& |g,printf("%-19s %s\n",$type,$a),$type=""/ges; }
  print STDERR $out;
}

sub Read {
  my $sock=shift; if ( $sock eq "INETD" ) { $sock = *STDIN;}
  my ($data,$len);
  debug("Reading","4 bytes");
  read ($sock,$data,4); debug("Read",$data);
  if ( $data =~ /^(.)(.)(.)(.)$/s ) { $len=(ord($1)*16777216 + ord($2)*65536 + ord($3)*256 + ord($4)); }
  else { return undef; }
  debug("Reading","$len bytes");
  read ($sock,$data,$len); debug("Read",$data);
  return $data;
}

sub Write {
  my $sock=shift; if ( $sock eq "INETD" ) { $sock = *STDOUT;}
  my $data=shift;
  my $datacont = Bin(sprintf("%08s",DecToHex(length($data))));
  debug("Sending",$datacont);
  print $sock $datacont;
  debug("Sending",$data);
  print $sock $data;
  return length($data);
}

my %SSLv3Errors = ( 0  => "Close notify", 		#warning/fatal 	
                    10 => "Unexpected message", 		#fatal 	
                    20 => "Bad record MAC", 		#fatal 	Possibly a bad SSL implementation, or payload has been tampered with. E.g., FTP firewall rule on FTPS server.
                    21 => "Decryption failed", 		#fatal 	TLS only, reserved
                    22 => "Record overflow", 		#fatal 	TLS only
                    30 => "Decompression failure", 	#fatal 	
                    40 => "Handshake failure", 		#fatal 	
                    41 => "No certificate", 		#warning/fatal 	SSL v3 only, reserved
                    42 => "Bad certificate", 		#warning/fatal 	
                    43 => "Unsupported certificate", 	#warning/fatal 	Eg certificate has only Server authentication usage enabled, and is presented as a client certificate
                    44 => "Certificate revoked", 		#warning/fatal 	
                    45 => "Certificate expired", 		#warning/fatal 	
                    46 => "Certificate unknown", 		#warning/fatal 	
                    47 => "Illegal parameter" 		#fatal 	
                  );

my %SSLv3Warnings = ( 0  => "Close notify",
                      41 => "No certificate",
                      42 => "Bad certificate",
                      43 => "Unsupported certificate",
                      44 => "Certificate revoked",
                      45 => "Certificate expired",
                      46 => "Certificate unknown"
                    );

sub ErrWarn { if ( ref($_[0]) eq "ARRAY" ) { push @{ $_[0]} , (caller(1))[3].": $_[1]"; } else { return [ (caller(1))[3].": $_[0]" ]; } }

# Parse message records
sub ParseRecords {
  my $records=shift;
  my %Hand;
  my @Order;
  while ($records =~ /^(.)(.)(.)(.)/s) {
    my ($id,$len) = (ord($1),(ord($2)*65536)+(ord($3)*256)+ord($4));
    $Hand{'Head'}{$id}=substr($records,0,4,'');  # Strip ID and Length bits
    $Hand{$id} = substr($records,0,$len,'');
    push @Order,$id;
    debug("Handshake $id","$Hand{$id}");
  }
  $Hand{'Order'}=\@Order;
  return %Hand;
}

###############################################

sub Keygen {
  my ($hexpremastersecret,$Crandom,$Srandom)=@_;
# MasterSecret
  my $hexmaster_secret='';
  foreach my $ABBCCC ("41","4242","434343") {
    my $tobesha1ed     = Bin($ABBCCC.$hexpremastersecret.$Crandom.$Srandom);
    my $tobemd5ed      = Bin($hexpremastersecret.Digest::SHA1::sha1_hex($tobesha1ed));
    $hexmaster_secret .= Digest::MD5::md5_hex($tobemd5ed);
  }
  my $ms = Bin($hexmaster_secret);
# Generate a key block
  my $kb='';
  foreach my $ABBCCC ("41","4242","434343","44444444","4545454545","464646464646","47474747474747") {
    my $tobesha1ed     = Bin($ABBCCC.$hexmaster_secret.$Srandom.$Crandom);
    my $tobemd5ed      = $ms.Digest::SHA1::sha1($tobesha1ed);
    $kb               .= Digest::MD5::md5($tobemd5ed);
  }
# Partition key block for DES+SHA1 and return
  my %keys=( MS => $ms, CMAC=>substr($kb,0,20), SMAC=>substr($kb,20,20), CK=>substr($kb,40,24), SK=>substr($kb,64,24), CIV=>substr($kb,88,8), SIV=>substr($kb,96,8) );
  foreach ( qw(MS CMAC SMAC CK SK CIV SIV) ) { debug("$_","$keys{$_}");}
  return %keys;
}

###############################################

sub Server {
  my %context=%{ $_[0]};
  my @error; 
  my @warning; ErrWarn(\@warning,"This function is experimnetal");

  if ( $] < 5.004 ) { ErrWarn(\@warning,"Perl version is old; random seed is not good"); }

# Check necessary inputs are set
  if ( ! defined $context{'Server'} )   { ErrWarn(\@error,"Server not Specified"); }
  if ( ! defined $context{'Port'} )     { ErrWarn(\@error,"Port not Specified"); }
  if ( ! defined $context{'Lifetime'} ) { ErrWarn(\@warning,"No Lifetime specified, setting limit to 12 hours"); }

  if ( ! defined $context{'Cert'} && ! defined $context{'CertFile'} )                              { ErrWarn(\@error,"Certificate not Specified"); }
  if ( ! defined $context{'Key'} && !  defined $context{'KeyFile'} )                               { ErrWarn(\@error,"Key not Specified"); }
  if ( ! defined $context{'Cert'} &&   defined $context{'CertFile'} && ! -r $context{'CertFile'} ) { ErrWarn(\@error,"Certificate file unreadable"); }
  if ( ! defined $context{'Key'} &&    defined $context{'KeyFile'} && ! -r $context{'KeyFile'} )   { ErrWarn(\@error,"Key file unreadable"); }

  if ( ! defined $context{'mapfile'} || ! -r $context{'mapfile'} )                                 { ErrWarn(\@error,"mapfile unreadable"); }

  if ( @error > 0 ) { return { Errors => \@error, Warnings => \@warning }; }

# Check format of input data
  my $Server       = (($context{'Server'}   =~ /^([a-z0-9_.-]+)$/) ? $& : undef);
  my $Port         = (($context{'Port'}     =~ /^([0-9]{1,5})$/ && $context{'Port'} < 65536) ? $& : undef);
  my $lifetime     = ((defined  $context{'Lifetime'}) ? ( ($context{'Lifetime'} =~ /^([0-9]+)$/s ) ? $& : undef ) : 43200 );

# Barf if data is not good
  if ( ! defined $Server )   { ErrWarn(\@error,"Bad VOMS server string"); }
  if ( ! defined $Port )     { ErrWarn(\@error,"Bad Port"); }
  if ( ! defined $lifetime ) { ErrWarn(\@error,"Invalid max lifetime"); }

# Check VOMS server Inputs: Cert, Key and CAdirs
  my @certs; my $key;
  if ( ref($context{'Cert'}) eq "ARRAY" )                             { @certs = @{ $context{'Cert'} }; }
  elsif ( defined($context{'Cert'}) and ref($context{'Cert'}) eq "" ) { @certs = ( $context{'Cert'} ); } #might consider a function to seperate concatenated DERs 
  elsif ( defined($context{'Cert'}) )                                 { ErrWarn(\@error,"Certs Argument was not an array reference nor a scalar"); }
  else                                                                { @certs = ( readCert($context{'CertFile'}) );}

  if ( ! @certs )                                                     { ErrWarn(\@error,"Unable to get any server certs."); }
  foreach my $i (0 .. $#certs) { if ( $certs[$i] !~ /^\x30/s )        { ErrWarn(\@error,"Supplied certificate (\@context{'Cert'}[$i]) $certs[$i] not in DER format"); } }

  if ( defined $context{'Key'} && $context{'Key'} !~ /^\x30/s )       { ErrWarn(\@error,"Key not in DER format"); }
  if ( defined $context{'Key'} )                                      { $key=$context{'Key'}; }
  else                                                                { $key=readPrivateKey($context{'KeyFile'}); }
  if (! defined($key) )                                               { ErrWarn(\@error,"Unable to get user key."); }

  my @CAdirs;
  if ( defined $context{'CAdirs'} ) {
    if ( ref($context{'CAdirs'}) eq "ARRAY" )                         { @CAdirs = @{ $context{'CAdirs'} }; }
    elsif ( ref($context{'Cert'}) eq "" )                             { @CAdirs = split(':',$context{'CAdirs'}); }
    else                                                              { ErrWarn(\@error,"CAdirs Argument was not a array reference nor a scalar"); }
  }

  foreach my $i (0 .. $#CAdirs) { if ( ! -d $CAdirs[$i] )             { ErrWarn(\@error,"Supplied CA directory (\@context{'CAdirs'}[$i]) is not a directory"); } }
  if ( @error > 0 ) { return { Errors => \@error, Warnings => \@warning }; }

#######################################
# If CAdirs is not defined try to get CAdirs from environment
  if ( ! @CAdirs and $ENV{X509_CERT_DIR} ) {
    if ( -d $ENV{X509_CERT_DIR} and $ENV{X509_CERT_DIR} =~ /^(.+)$/) { push @CAdirs,$1; }
    else { return { Errors => ErrWarn("X509_CERT_DIR defined but it is not a directory"), Warnings => \@warning }; }
  }
  elsif ( ! @CAdirs ) {
    if ( -d $CAdir ) { push @CAdirs, $CAdir; ErrWarn(\@warning,"No CAdirs specified Using $CAdir"); }
    else { return {   Errors => ErrWarn('No CAdir found'), Warnings => \@warning }; }
  }


#######################################
# Listen on $socket $port if INETD is not set
  my  $sock="INETD";
  if ( ! defined $context{Inetd} ) {
    my $socklistener = new IO::Socket::INET ( LocalHost => $Server, LocalPort => $Port, Proto => 'tcp', Listen => 1, Reuse => 1, );
    die "dead" unless $socklistener;
    return { Errors => ["Unable to listen on $Server:$Port"], Warnings => \@warning } unless $socklistener;
    $socklistener->autoflush(1);
    $sock = $socklistener->accept(); 
  }

#######################################
# Listen for ClientHello

  my $response=Read($sock);

  my $hexclienthellorecord=Hex($response);
  my $records="";
  my @clienthello;
  while (length($response) > 0) {
    my $lenstr=substr($response,0,5,'');
    my $len;
    if ($lenstr =~ /^\x16\x03\x00(.)(.)/s ) { $len=ord($1)*256+ord($2); }
    else { return { Errors => ["Malformed SSL header from client while waiting for SSL ClientHello messages"], Warnings => \@warning }; }
    push @clienthello,Hex($lenstr.substr($response,0,$len));
    $records.=substr($response,0,$len,'');
  }

  my $Hmsgs=$records;   ###Used to verify client cert later

# Parse Handshake message records
  my %Hand = ParseRecords($records);

  #Get ClientHello bits and pieces
  my $cHello                     = $Hand{1};
  my $cHelloVer                  = substr($cHello,0,2,'');
  my $cHelloTime                 = substr($cHello,0,4,'');
  my $cHelloRand                 = substr($cHello,0,28,'');
  my $cHelloIDlen                = ord(substr($cHello,0,1,''));
  my $cHelloSessionID            = substr($cHello,0,$cHelloIDlen,'');
  my $cHelloCypherSuiteslen      = substr($cHello,0,2,'');
  my $CSlen                      = (ord(substr($cHelloCypherSuiteslen,0,1))*256) + ord(substr($cHelloCypherSuiteslen,1,1));
  my $cHelloCypherSuites         = substr($cHello,0,$CSlen,'');
  my $cHelloCompressionMethodlen = ord(substr($cHello,0,1,''));
  my $cHelloCompressionMethod    = substr($cHello,0,$cHelloCompressionMethodlen,''); 
  debug("cHello",$Hand{1});
  debug("cHelloVer","$cHelloVer");
  debug("cHelloTime","$cHelloTime");
  debug("cHelloRand","$cHelloRand");
  debug("cHelloIDlen","$cHelloIDlen");
  debug("cHelloSessionID","$cHelloSessionID");
  debug("cHelloCypherSuiteslen","$cHelloCypherSuiteslen");
  debug("CSlen",$CSlen);
  debug("cHelloCypherSuites","$cHelloCypherSuites");
  debug("CMlen",$cHelloCompressionMethodlen);
  debug("cHelloCompressionMethod","$cHelloCompressionMethod");

  #check for the (only) cyphersuite I support
  return { Errors => ["No Common Cyphersuite supported"], Warnings => \@warning } if ( $cHelloCypherSuites !~ /^(..)*?\x00\x0a/ );
  return { Errors => ["No Common Cyphersuite supported"], Warnings => \@warning } if ( $cHelloCompressionMethod !~ /\x00/ );
  #All implementations must support compression method 00

  # Send Server Hello
  my $hextime               = DecToHex(time);
  my $time                  = Bin($hextime);
  my $rnd = "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"; $rnd =~ s/./chr(int(rand 256))/ge;#not so good on Win32 32000 cycle reported
  my $hexrnd                = Hex($rnd);
  my $hexrandom             = $hextime.$hexrnd;
  my $ses = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"; $ses =~ s/./chr(int(rand 256))/ge;   ### Not used
  my $hexsession            = "20".Hex($ses);
  my $hexcypher             = "000a";  #Ciphersuite TLS_RSA_WITH_3DES_EDE_CBC_SHA
  my $hexcompression        = "00"; #CompressionMeth  - Use none no need data minimal + this is a lite implementation
  my $hexssl_version        = "0300";
#  my $hexhandshake_parts    = $hexssl_version.$hexrandom.$hexsession.$hexcypher.$hexcompression;
  my $hexhello              = handShake("02",$hexssl_version.$hexrandom.$hexsession.$hexcypher.$hexcompression);
  my $hexhellorecord        = recordLayer("16",$hexhello);

  $Hmsgs .= Bin($hexhello);

############
# CA names message
  my @CAfiles;
  foreach my $DIR (@CAdirs) { opendir(my $dh, $DIR); foreach (grep { /\.[0-9]+$/ && -f "$DIR/$_" } readdir($dh)) { push @CAfiles, $DIR."/".$_; } closedir $dh; }

  my $hexcacerts="";

  foreach $cafile (@CAfiles) {
    my $DER      = readCert("$cafile");
    my %certinfo = %{ VOMS::Lite::X509::Examine( $DER, { X509subject => "" }) };
    debug ("X509Subject","$certinfo{X509subject}");
    $hexcacerts.=sprintf("%04s",DecToHex(length($certinfo{'X509subject'}))).Hex($certinfo{'X509subject'});
  }

  $hexcacerts="020102".sprintf("%04s",DecToHex(length($hexcacerts)/2)).$hexcacerts; #####Perhaps 0101 rather than 020102

  my $RSACertreq = handShake("0d",$hexcacerts);

  $Hmsgs.=Bin($RSACertreq);

# Construct Server Certificate Message
# Get details from Cert
  my %chain    = %{ VOMS::Lite::CertKeyHelper::buildchain( { trustedCAdirs => \@CAdirs, suppliedcerts => \@certs } ) };
  my @chain    = @{ $chain{'Certs'} };
  my $certmsgcerts; foreach ( @chain ) { $certmsgcerts.=sprintf("%06s",DecToHex(length($_))).Hex($_); }
  $certmsgcerts = sprintf("%06s",DecToHex(length($certmsgcerts)/2)).$certmsgcerts;
  my $hexServerCertMsg = handShake("0b",$certmsgcerts);

  $Hmsgs .= Bin($hexServerCertMsg);

# Construct ServerFinished
  my $ServerFinished = handShake("0e","");

  $Hmsgs.=Bin($ServerFinished);

# Send Server Hello Record
  Write($sock,Bin($hexhellorecord.recordLayer("16",$RSACertreq.$hexServerCertMsg.$ServerFinished)));

############################  Wait for client
#Expect: 'hexcertsmessagerecord','hexClientKeyExchangeMessageRecord','hex_ssl_certificateverifyrecord','hexkeyselection','hex_finishedrecord'

  $response=Read($sock);
  my $hexclientresponse=Hex($response);
  my $records=""; my $changecypher;
  my @clientResponse;
  while (length($response) > 0) {
    my $lenstr=substr($response,0,5,'');
    my $len;
    if ($lenstr =~ /^\x16\x03\x00(.)(.)/s ) { $len=ord($1)*256+ord($2); }
    elsif ($lenstr =~ /^\x14\x03\x00(.)(.)/s ) {
      $len=ord($1)*256+ord($2);
      $changecypher=substr($response,0,$len,''); #CCS 
      return { Errors => ["Unknown Encryption Message"], Warnings => \@warning } unless ($changecypher =~ /^\x01$/ ); 
      last;
    }
    else { return { Errors => ["Malformed SSL header from client while waiting for SSL messages"], Warnings => \@warning }; }
    push @clientResponse,Hex($lenstr.substr($response,0,$len));
    $records.=substr($response,0,$len,'');
  }

  my $clienthellomsgs2=""; #### used in verify step
  my $clienthellomsgs3=""; #### Used in hello finished verification

  my %Hand = ParseRecords($records);
  foreach (@{ $Hand{'Order'} }) { last if ($_ eq "15"); $Hmsgs.=$Hand{'Head'}{$_}.$Hand{$_}; }

#Get the client certificate - 1, Verify it 2, key material for pre-master key exchange later
  my $certcont = $Hand{11};
  my $lcerts = substr($certcont,0,3,'');
  my @CLIcerts=();
  while ( length($certcont)>3 && ($lcert=substr($certcont,0,3,''))) {
    if ($lcert =~ /(.)(.)(.)/s ) { push @CLIcerts, substr($certcont,0,(ord($1)*65536)+(ord($2)*256)+ord($3),''); }
  }
  return { Errors => ["No cert returned from client"], Warnings => \@warning } unless (@CLIcerts);
  my %ClientCertInfo= %{ VOMS::Lite::X509::Examine( $CLIcerts[0], { SubjectDN=>"", IssuerDN=>"", Keymodulus=>"", KeypublicExponent=>"", subjectAltName=>"" }) };
  my $ClientDN=$ClientCertInfo{'SubjectDN'};
#  my @SubjectAltNames=@{ $ClientCertInfo{'subjectAltNameArray'} }; foreach (@SubjectAltNames) { debug("Altname",$_); } 
  debug("Client DN",$ClientDN);

#Get the client key exchange message
  my $keyexchange = $Hand{16};
  my %KeyInfo = %{ VOMS::Lite::KEY::Examine($key, {Keymodulus=>"", KeyprivateExponent=>""} ) };
  my $hexpremastersecret = rsadecrypt(Hex($keyexchange),Hex($KeyInfo{KeyprivateExponent}),Hex($KeyInfo{Keymodulus}));
  return {Errors => ["VOMS::Lite::VOMS::Server: Premaster Secret received from client did not decrypt correctly with Server's private key"], 
          Warnings => \@warning } if ($hexpremastersecret !~ /^0300.{92}$/s );

###########################################
# Build and verify client certificate chain

  foreach (@CAdirs) { debug("CADIR","$_")};
  my %Chain = %{ buildchain( { trustedCAdirs => \@CAdirs, suppliedcerts => \@CLIcerts } ) };
  my @returnedCerts = @{ $Chain{Certs} }; 
  my @Trust         = @{ $Chain{TrustedCA} };
  my $EECDN         =    $Chain{EndEntityDN};
  my $EECIDN        =    $Chain{EndEntityIssuerDN};
  my $EEC           =    $Chain{EndEntityCert};
  my @Errors        = @{ $Chain{Errors} };

#Check for cerification errors in client certificate
  ErrWarn(\@warning, "NO CRL Check implemented");
  ErrWarn(\@warning, "NO Certificate Purpose Check implemented");
  ErrWarn(\@warning, "NO CA signing policy check implemented");
  for (my $i=0;$i < $#Errors;$i++ ) { if ( @{ $Errors[$i] } ) { ErrWarn(\@error,"Error verifying client's certificate chain (depth $i): ".join(", ",@{ $Errors[$i] })); } }
  ErrWarn(\@error,"Client's Certificate is not trusted by server") unless ($Trust[-1]);
  return { Errors => \@error, Warnings => \@warning } if (@error);


#Derive Key Material
  my %KEYS=Keygen($hexpremastersecret,Hex($cHelloTime.$cHelloRand),$hexrandom); 

# Derive Certificate Verify
  my $verifymac = MAC($KEYS{'MS'},$Hmsgs);

# Decrypt (verify) Certificate Verify
  my $TBVverifymac=$Hand{15};
  my $TBVverifymaclen=(ord(substr($TBVverifymac,0,1,''))*256) + ord(substr($TBVverifymac,0,1,''));
  if ( length($TBVverifymac) != $TBVverifymaclen ) { return { Errors => ErrWarn("Certificate Verification failed verify Mac length mismatch"), Warnings => \@warning }; }
  my $verifyData = rsaverify(Hex($TBVverifymac),Hex($ClientCertInfo{KeypublicExponent}),Hex($ClientCertInfo{Keymodulus}));

  if ($verifyData ne $verifymac) { return { Errors => ErrWarn("Certificate Verification failed verify Mac mismatch"), Warnings => \@warning }; }

# Set up the Client and Server DES3-EDE sessions
  my $Ccipher = Crypt::CBC->new( -literal_key => 1, -padding => 'null', -key => $KEYS{'CK'},  -iv => $KEYS{'CIV'}, -header => 'none', -cipher => 'DES_EDE3' );
  my $Scipher = Crypt::CBC->new( -literal_key => 1, -padding => 'null', -key => $KEYS{'SK'},  -iv => $KEYS{'SIV'}, -header => 'none', -cipher => 'DES_EDE3' );
  my $Cseq=0;
  my $Sseq=0;

# Decrypt received finished message and check against locally derived message
  $Hmsgs.=$Hand{'Head'}{15}.$Hand{15};
  my $clientfinishedhex=Hex(&Decrypt($response,$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher));
  my $unechexfinished = handShake("14",MAC($KEYS{'MS'},$Hmsgs."CLNT"));
  if ($clientfinishedhex ne $unechexfinished) { return { Errors => ["Hello Finished decryption failed"], Warnings => \@warning }; }

# Send Change Cipher Spec and Server Finished
  my $hexkeyselection="140300000101";

  my $unechexfinished = handShake("14",MAC($KEYS{'MS'},$Hmsgs.Bin($unechexfinished)."SRVR"));
  my $hex_finishedrecord = &Encrypt(Bin(recordLayer("16",$unechexfinished)),$KEYS{'SMAC'},$pad1sha,$pad2sha,$Sseq,$Scipher);
  my $hex_finished       = $hex_finishedrecord;
  $hex_finished         =~ s/^..........//s;

  Write($sock,Bin($hexkeyselection.$hex_finishedrecord));

# Read GSI Data
  $response=Read($sock);

  if ( $response !~ /^\x17/ ) { return { Errors => ErrWarn("Expecting Encrypted Application Data, got something else"), Warnings => \@warning }; }
  my $apdata=&Decrypt($response,$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher);

  if ( $apdata ne "0" ) { return { Errors => ErrWarn("Client Requested Delegation"), Warnings => \@warning }; }

####################################################
# GSI Secured Channel now in operation

  $response=Read($sock);

  if ( $response !~ /^\x17/ ) { return { Errors => ["Expecting Encrypted Application Data, got something else"], Warnings => \@warning }; }
  my $apdata=&Decrypt($response,$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher);

  my @W; my @E;

  my ($VOMSReq)  = $apdata =~ m{<voms>(.*)</voms>};
  my @Command    = $VOMSReq =~ m{<command>([^<]*)</command>}g;
  my ($Base)     = $VOMSReq =~ m{<base64>([^<]*)</base64>};
  my ($Version)  = $VOMSReq =~ m{<version>([^<]*)</version>};
  my ($Lifetime) = $VOMSReq =~ m{<lifetime>([0-9]*)</lifetime>};
  if ($Lifetime > $lifetime) { 
    ErrWarn(\@warning,"Lifetime requested too large. Defaulting to $lifetime");
    push @W,"<item><number>901</number><message>Lifetime $Lifetime too large defaulting to ${lifetime}s</message></item>"; 
  } else { $lifetime = $Lifetime }

  my ($Order)    = $VOMSReq =~ m{<order>([^<]*)</order>};
  my ($Target)   = $VOMSReq =~ m{<targets>([^<]*)</targets>};

  foreach (@Command) { debug("Command",$_); }
  debug("Base",$Base);
  debug("Version",$Version);
  debug("Lifetime",$Lifetime);
  debug("Order",$Order);
  debug("Target",$Target);

  my $Data='<xml version="1.0" encoding = "US-ASCII"?><vomsans>';

  my @CommandData;
  foreach (@Command) {
    if ( m{^G(/.*)} ) { push @CommandData,$1; }
    else { push @E,"<item><number>1901</number><message>Command $_ unsupported</message></item>"; }
  }

# Look for AC release authority in gridmapfile
  my %allowed;
  open(GMFILE,$context{mapfile}) or return {Errors => ErrWarn("Unable to open $context{mapfile}"), Warnings => \@warning };
  foreach (<GMFILE>) { if ( /^\s*"$EECDN"\s+(.*)/ ) { debug ("Found Auth",$1); foreach (split /\s+/,$1) {$Allowed{$_}=1;}  last;} }
  close GMFILE;

  foreach (@CommandData) { if ( ! defined $Allowed{$_} ) {push @E,"<item><number>1902</number><message>$EECDN not authorised for $_</message></item>";} }

  if (@E) { $Data.="<error>"; foreach(@E) { $Data.=$_; } $Data.="</error>";}  #Error codes are wrong
  else {
    my $acref = VOMS::Lite::AC::Create( { Cert     => $EEC,
                                          VOMSCert => $certs[0],
                                          VOMSKey  => $key,
                                          Lifetime => $lifetime,
                                          Server   => $Server,
                                          Port     => $Port,
                                          Serial   => time(),   #Reasonably different --- Could do better
                                          Code     => $Port,
                                          Attribs  => \@CommandData
                                         } );
    foreach (@$acref{Errors}) {  debug("Error",join(",",@$_)) if (@$_); }
    debug("AC",$$acref{AC});
    my $CODEDAC=VOMS::Lite::Base64::Encode($$acref{AC},($Base==1)?"RFC3548":"VOMS");
#  <bitstr>CODEDDATA</bitstr>

    if (@W) { $Data.="<error>"; foreach(@W) { $Data.=$_; } $Data.="</error>";}    
    $Data.="<ac>$CODEDAC</ac>";
    $Data.="<version>4</version>";  
  }
  $Data.="</vomsans>";

# predata to stop TLS CBC IV attack
  my $predata      = Bin(&Encrypt(Bin("1703000000"),$KEYS{'SMAC'},$pad1sha,$pad2sha,$Sseq,$Scipher)); 
  Write($sock,$predata.Bin(&Encrypt(Bin(recordLayer("17",Hex($Data))),$KEYS{'SMAC'},$pad1sha,$pad2sha,$Sseq,$Scipher)));

  return { Warnings => \@warning };
}

#########################################

sub Get {
  my %context=%{ $_[0]};
  my @error; my @warning;

  if ( $] < 5.004 ) { ErrWarn(\@warning, "Perl version is old; random seed is not good"); }

  if ( ! defined $context{'Server'} )   { ErrWarn(\@error, "Server not Specified"); }
  if ( ! defined $context{'Port'} )     { ErrWarn(\@error, "Port not Specified"); }
  if ( ! defined $context{'FQANs'} )    { ErrWarn(\@error, "No FQANs requested"); }
  if ( ! defined $context{'Lifetime'} ) { ErrWarn(\@warning, "No Lifetime specified, requesting 12 hours");  }

# IO::SOCKET::SSL may optionally use a cert and key on the file system, we too;
  if ( ! defined $context{'Cert'} && ! defined $context{'CertFile'} ) { ErrWarn(\@error, "Certificate not Specified"); }
  if ( ! defined $context{'Key'} && ! defined $context{'KeyFile'} )   { ErrWarn(\@error, "Key not Specified"); }
  if ( ! defined $context{'Cert'} && defined $context{'CertFile'} && ! -r $context{'CertFile'} ) { ErrWarn(\@error, "Certificate file unreadable"); }
  if ( ! defined $context{'Key'} && defined $context{'KeyFile'} && ! -r $context{'KeyFile'} ) { ErrWarn(\@error, "Key file unreadable"); }

  if (ref( $context{'FQANs'} ) ne 'ARRAY') { ErrWarn(\@error,"FQANs must be a reference to an array of FQANs."); }
  if ( @error > 0 ) { return { Errors => \@error, Warnings => \@warning }; }

  my $Server       = (($context{'Server'}   =~ /^([a-z0-9_.-]+)$/) ? $& : undef);
  my $Port         = (($context{'Port'}     =~ /^([0-9]{1,5})$/ && $context{'Port'} < 65536) ? $& : 7512);
  my $lifetime     = ((defined  $context{'Lifetime'}) ? ( ($context{'Lifetime'} =~ /^([0-9]+)$/s ) ? $& : undef ) : 43200 );
  my @FQANs        = @{ $context{'FQANs'} };
  foreach (@FQANs) { if (!m{^/[a-zA-Z0-9_.-]+(/[^/]+)*$}) { ErrWarn(\@error, "\"$_\" is not a valid FQAN."); } }

# Barf if data is not good
  if ( ! defined $Server )         { ErrWarn(\@error, "Bad VOMS server string"); }
  if ( ! defined $Port )           { ErrWarn(\@error, "Bad Port"); }
  if ( ! defined $lifetime )       { ErrWarn(\@error, "Invalid Lifetime $context{'Lifetime'}. Must be a positive integer. e.g. 43200 for 12h"); }

  my @certs; my $key;
  if ( ref($context{'Cert'}) eq "ARRAY" ) { @certs = @{ $context{'Cert'} }; }
  elsif ( defined($context{'Cert'}) and ref($context{'Cert'}) eq "" )   { @certs = ( $context{'Cert'} ); } #might consider a function to seperate concatenated DERs 
  elsif ( defined($context{'Cert'}) )     { ErrWarn(\@error, "Certs Argument was not a reference to an array nor a scalar"); }
  else { @certs = ( readCert($context{'CertFile'}) );}
  if ( ! @certs ) { ErrWarn(\@error, "Unable to get any user certs."); }
  foreach my $i (0 .. $#certs) { if ( $certs[$i] !~ /^\x30/s ) { ErrWarn(\@error, "Supplied certificate (\@context{'Cert'}[$i]) $certs[$i] not in DER format"); } }

  if ( defined $context{'Key'} && $context{'Key'} !~ /^\x30/s ) { ErrWarn(\@error, "Supplied Key not in DER format"); }
  if ( defined $context{'Key'} ) { $key=$context{'Key'}; }
  else { $key=readPrivateKey($context{'KeyFile'}); }
  if (! defined($key) ) { ErrWarn(\@error, "Unable to get user key."); }

  my @CAdirs;
  if ( defined $context{'CAdirs'} ) {
    if ( ref($context{'CAdirs'}) eq "ARRAY" ) { @CAdirs = @{ $context{'CAdirs'} }; }
    elsif ( ref($context{'Cert'}) eq "" )   { @CAdirs = split(':',$context{'CAdirs'}); }
    else { ErrWarn(\@error, "CAdirs Argument was not a reference to an array nor a scalar"); }
  }

  foreach my $i (0 .. $#CAdirs) { if ( ! -d $CAdirs[$i] ) { ErrWarn(\@error, "Supplied CA directory (\@context{'CAdirs'}[$i]) is not a directory"); } }

  if ( @error > 0 ) { return { Errors => \@error, Warnings => \@warning }; }

#Need CAdirs
#==========================================================
  if ( ! @CAdirs and $ENV{X509_CERT_DIR} ) {
    if ( -d $ENV{X509_CERT_DIR} and $ENV{X509_CERT_DIR} =~ /^(.*)$/) { push @CAdirs,$1; }
    else { return { Errors => ErrWarn('X509_CERT_DIR defined but it is not a directory'), Warnings => \@warning }; }
  }
  elsif ( ! @CAdirs ) {
    if ( -d $CAdir ) { push @CAdirs, $CAdir; ErrWarn(\@warning,"no CAdir specified Using $CAdir"); }
    else { return {   Errors => ErrWarn('No CAdir found'), Warnings => \@warning }; }
  }

# Get details from Cert and Key
  my %certinfo = %{ VOMS::Lite::X509::Examine( $certs[0], { SubjectDN=>"", IssuerDN=>"" }) };
  my %chain    = %{ VOMS::Lite::CertKeyHelper::buildchain( { trustedCAdirs => \@CAdirs, suppliedcerts => \@certs } ) };
  my @chain    = @{ $chain{'Certs'} };
  my $UserDN   = $chain{'EndEntityDN'};
  my $UserIDN  = $chain{'EndEntityIssuerDN'};
  my %keyinfo  = %{ VOMS::Lite::KEY::Examine( $key, { Keymodulus=>"",KeyprivateExponent=>"" }) };
  my $Keymod   = Hex($keyinfo{'Keymodulus'});
  my $Keyexp   = Hex($keyinfo{'KeyprivateExponent'});
  my $DN       = $certinfo{'SubjectDN'};
  my $IDN      = $certinfo{'IssuerDN'};

#Open a socket to the server
  my $sock = new IO::Socket::INET( PeerAddr => $Server, PeerPort => $Port, Proto => 'tcp', Type => SOCK_STREAM); 
  if ( ! defined ($sock) ) { return { Errors => ErrWarn("Unable to establish a connection to $Server:$Port"), Warnings => \@warning }; }
  $sock->autoflush(1);

#######################################
#Construct Initial Components required for SSL 
#Random
  my $hextime               = DecToHex(time);
  my $time                  = Bin($hextime);
  my $rnd = "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"; $rnd =~ s/./chr(int(rand 256))/ge;#not so good on Win32 32000 cycle reported
  my $hexrnd                = Hex($rnd);
  my $hexrandom             = $hextime.$hexrnd;
  my $hexsession            = "00";   #none - new session
  my $hexcypher_vec         = "000a";  #Ciphersuite TLS_RSA_WITH_3DES_EDE_CBC_SHA
  my $hexcypher_suits       = sprintf("%04s",DecToHex(length($hexcypher_vec)/2)).$hexcypher_vec;
  my $hexcompression_vec    = "00"; #CompressionMeth  - Use none no need data minimal + this is a lite implementation
  my $hexcompression        = sprintf("%02s",DecToHex(length($hexcompression_vec)/2)).$hexcompression_vec;
  my $hexssl_version        = "0300";
  my $hexhandshake_parts    = $hexssl_version.$hexrandom.$hexsession.$hexcypher_suits.$hexcompression;
  my $hexhello              = handShake("01",$hexhandshake_parts);
  my $clienthello           = Bin($hexhello); 
  my $hexhellorecord        = recordLayer("16",$hexhello);

#######################################
#Send Client Hello Record
  my $hellorecord           = Bin($hexhellorecord); #Client Hello Record ready to send
  Write($sock,$hellorecord);

#######################################
# Listen for ServerHello
  my $response=Read($sock);
  my $hexserverhellorecord=Hex($response);
  my $records="";
  while (length($response) > 0) {
    my $lenstr=substr($response,0,5,'');
    my $len;
    if ($lenstr =~ /^\x16\x03\x00(.)(.)/s ) { $len=ord($1)*256+ord($2); }
    else { return { Errors => ErrWarn("Malformed SSL header from server while waiting for SSL ServerHello messages"), Warnings => \@warning }; }
    $records.=substr($response,0,$len,'');
  }
  my $serverhello=$records;

#######################################
# Decode ServerHandshake Messages
  my %Hand = ParseRecords($records);

# Get the host certificate - 1, Verify VOMS cert 2, key material for pre-master key exchange later
  my $certcont = $Hand{11};
  my $lcerts = substr($certcont,0,3,'');
  my @HOSTcerts=();
  while ( length($certcont)>3 && ($lcert=substr($certcont,0,3,''))) { 
    if ($lcert =~ /(.)(.)(.)/s ) { push @HOSTcerts, substr($certcont,0,(ord($1)*65536)+(ord($2)*256)+ord($3),''); }
  }
  return { Errors => ErrWarn("No cert returned from server"), Warnings => \@warning } unless (@HOSTcerts);

# Build VOMS Server Chain Locally and check it's trusted
  my %Chain  = %{ buildchain( { trustedCAdirs => \@CAdirs, suppliedcerts => \@HOSTcerts } ) };
  my @Trust  = @{ $Chain{TrustedCA} };
  my @Errors = @{ $Chain{Errors} };
  my $EEC           =    $Chain{EndEntityCert};
  ErrWarn(\@warning, "NO CRL Check implemented");
  ErrWarn(\@warning, "NO Certificate Purpose Check implemented");
  ErrWarn(\@warning, "NO CA signing policy check implemented");
  for (my $i=0;$i < $#Errors;$i++ ) { if ( @{ $Errors[$i] } ) { ErrWarn(\@error,"Error verifying server's certificate chain (depth $i): ".join(", ",@{ $Errors[$i] })); } }
  ErrWarn(\@error,"Server's Certificate is not trusted by client") unless ($Trust[-1]);
  return { Errors => \@error, Warnings => \@warning } if (@error);

# Extract Server Cert and Key details
  my %ServerCertInfo= %{ VOMS::Lite::X509::Examine( $EEC, { SubjectDN=>"", IssuerDN=>"", Keymodulus=>"", KeypublicExponent=>"", subjectAltName=>"" }) };
  my $ServerDN=$ServerCertInfo{'SubjectDN'};
  my @SubjecyAltNames=@{ $ServerCertInfo{'subjectAltNameArray'} };
  debug("Server DN",$ServerDN);
# Check server certificate matches ! Not matching against wildcards 
  if ($ServerDN !~ m#/CN=($Server)(/|$)#) {
    my $match=0;
# Else Check Subject Alt Name matches
    foreach (@SubjecyAltNames) { debug("AltName",$_); if ($_ eq "dNSName=$Server") {$match=1; ErrWarn(\@warning,"Using SubjectAltName to Match VOMS Server Certificate")} }
    return { Errors => ErrWarn("Server Distinguished name mismatch expecting Certificate name containing CN=$Server got $ServerDN"), Warnings => \@warning } 
     if (!$match && $Server ne "localhost");
  }

# Get ServerHello bits and pieces
  my $sHello                  = $Hand{2};
  my $sHelloVer               = substr($sHello,0,2,'');
  my $sHelloTime              = substr($sHello,0,4,'');
  my $sHelloRand              = substr($sHello,0,28,'');
  my $sHelloIDlen             = ord(substr($sHello,0,1,''));
  my $sHelloSessionID         = substr($sHello,0,$sHelloIDlen,'');
  my $sHelloCypherSuite       = substr($sHello,0,2,'');
  my $sHelloCompressionMethod = substr($sHello,0,1,'');
  debug("Session ID",$sHelloSessionID);

# Get Certificate Request (request for authN)
  my $sRequest=$Hand{13};
  my $ReqTypesCount=ord(substr($sRequest,0,1,''));
  my $RSAOK=0;
  my @ReqTypes; for (my $a=0; $a<$ReqTypesCount; $a++) { push @ReqTypes,substr($sRequest,0,1,''); if ($ReqTypes[-1] eq "\x01") {$RSAOK=1;} }
  my $ReqDNNamesLen=(ord(substr($sRequest,0,1,''))*256)+ord(substr($sRequest,0,1,''));
  my $ReqDistinguishedNames=substr($sRequest,0,$ReqDNNamesLen,'');
  my @ReqASN1DN;
  while ( length($ReqDistinguishedNames) > 0 ) {
    my $DNLen=(ord(substr($ReqDistinguishedNames,0,1,''))*256)+ord(substr($ReqDistinguishedNames,0,1,''));
    push @ReqASN1DN,substr($ReqDistinguishedNames,0,$DNLen,'');
  }

# Get ServerHelloDone
  my $sHelloDone=$Hand{14};

# Check for RSA
  if ($RSAOK==0) { return { Errors => ErrWarn("Server does not support RSA AuthN"), Warnings => \@warning }; } 

# 1, Check acceptable DNs for Certificates
  my $GotCA=0;
  foreach (@ReqASN1DN) {
    my $X509subject=$_;
    my @ASN1SubjectDNIndex=ASN1Index($X509subject);
    shift @ASN1SubjectDNIndex;
    my $SubjectDN="";
    while (@ASN1SubjectDNIndex) {
      my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN)=(0,0,0,0,0);
      until ($TAG == 6 ) { ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ASN1SubjectDNIndex}; }
      my $OID=substr($X509subject,($HEADSTART+$HEADLEN),$CHUNKLEN);
      ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ASN1SubjectDNIndex};
      my $Value=substr($X509subject,($HEADSTART+$HEADLEN),$CHUNKLEN);
      $SubjectDN.="/".VOMS::Lite::CertKeyHelper::OIDtoDNattrib(ASN1OIDtoOID($OID))."=$Value";
    }
    if ($UserIDN eq $SubjectDN) { debug("MATCHED CA",$SubjectDN); $GotCA=1; } 
    else                        { debug("        CA:", $SubjectDN); }
  }
  if ( @ReqASN1DN == 0 ) { ErrWarn(\@warning, "VOMS server does not tell me what CAs are supported"); }
  elsif ( $GotCA==0 )    { return { Errors => ErrWarn("VOMS server does not support your CA"), Warnings => \@warning }; }

#########################################################
#Talk to the server again

##Construct Certificate Message Record
  my $hexcertarray =""; 
  foreach my $cert (@chain) { $hexcertarray.=sprintf("%06s",DecToHex(length($cert))).Hex($cert);}
  my $hexcertobj      = sprintf("%06s",DecToHex(length($hexcertarray)/2)).$hexcertarray;
  my $hexcertmesg     = handShake("0b",$hexcertobj);
  my $hexcertsmessagerecord=recordLayer("16",$hexcertmesg);
  my $certmesg = pack("H*", $hexcertmesg); 

##ClientKeyExchange
#PreMasterSecret
  my $prernd='X' x 46;  $prernd =~ s/./chr(int(rand 256))/ge;
  my $hexpremastersecret='0300'.Hex($prernd);

#Derive Key Material
  my %KEYS=Keygen($hexpremastersecret,$hexrandom,Hex($sHelloTime.$sHelloRand));

#Make Client Key Exchange
  my $hexEncPMSecret   = rsaencrypt($hexpremastersecret,Hex($ServerCertInfo{'KeypublicExponent'}),Hex($ServerCertInfo{'Keymodulus'}));
  my $hexClientKeyExchange  = handShake("10",$hexEncPMSecret);    #### USE ME FOR CertificateVarify
  my $hexClientKeyExchangeMessageRecord = recordLayer("16",$hexClientKeyExchange);
  my $ClientKeyExchangeMessage = Bin($hexClientKeyExchange); #### ClientCertificate for handshakemessages needs to be without record layer

#CertificateVerify
  my $Hmsgs     = $clienthello.$serverhello.$certmesg.$ClientKeyExchangeMessage;
  my $verifymac = MAC($KEYS{'MS'},$Hmsgs);

  my $hexsignedcertificateverify        = rsasign($verifymac,$Keyexp,$Keymod);
  my $hexwrappedsignedcertificateverify = sprintf("%04s",DecToHex(length($hexsignedcertificateverify)/2)).$hexsignedcertificateverify;
  my $hexcertificateverify              = handShake('0f',$hexwrappedsignedcertificateverify);
  my $certificateverify                 = Bin($hexcertificateverify);
  my $hex_ssl_certificateverifyrecord   = recordLayer("16",$hexcertificateverify);

##########################################################################
## Switch to Encrypted Session -- change_cipher_spec message
#Select algorythm for key exchange -- Must be RSA
  my $hexkeyselection="140300000101";

# Switch to tripple des (the only one I support) and send finished message

  $Hmsgs.=$certificateverify;
  my $unechexfinished=handShake("14",MAC($KEYS{'MS'},$Hmsgs."CLNT"));

#Set up the Client and Server DES3-EDE sessions
  my $Ccipher = Crypt::CBC->new( -literal_key => 1, -padding => 'null', -key => $KEYS{'CK'},  -iv => $KEYS{'CIV'}, -header => 'none', -cipher => 'DES_EDE3' );
  my $Scipher = Crypt::CBC->new( -literal_key => 1, -padding => 'null', -key => $KEYS{'SK'},  -iv => $KEYS{'SIV'}, -header => 'none', -cipher => 'DES_EDE3' );
  my $Cseq=0;
  my $Sseq=0;

  my $hex_finishedrecord = &Encrypt(Bin(recordLayer("16",$unechexfinished)),$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher);
  my $hex_finished       = $hex_finishedrecord;
  $hex_finished         =~ s/^..........//s;
  my $finished           = Bin($hex_finished);

#############################################################################
#Send Records
  Write($sock,Bin($hexcertsmessagerecord.$hexClientKeyExchangeMessageRecord.$hex_ssl_certificateverifyrecord.$hexkeyselection.$hex_finishedrecord));

#############################################################################
#Receive Response
  $response=Read($sock);
  if ( $response =~ /^\x14\x03\x00\x00\x01\x01/ ) {  $response =~ s/......//; } #Change Cypher Spec -- what we expect
  else { return { Errors => ErrWarn("Error: Expecting SSL Change Cypher Spec Message, got something else."), Warnings => \@warning }; }
  my $serverfinishedhex=Hex(&Decrypt($response,$KEYS{'SMAC'},$pad1sha,$pad2sha,$Sseq,$Scipher));

# Check response from server is a valid finished message
  $Hmsgs.=Bin($unechexfinished);
  my $unencryptedfinishedmsg = handShake("14",MAC($KEYS{'MS'},$Hmsgs."SRVR"));
  if ($unencryptedfinishedmsg ne $serverfinishedhex) { return { Errors => ErrWarn("Failed to decrypt Server Finished Message"), Warnings => \@warning }; }

######################### 
# Send no delegation byte
# predata and postdata to stop TLS CBC IV attack
  my $predata      = Bin(&Encrypt(Bin("1703000000"),$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher));
  my $msg='0';
  my $emesg        = &Encrypt(Bin(recordLayer("17",Hex($msg))),$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher);
  $senddata        = Bin($emesg);
  my $postdata     = Bin(&Encrypt(Bin("1703000000"),$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher));

  Write($sock,$predata.$senddata.$postdata);

############## 
# Send request
#<xml version="1.0" encoding = "US-ASCII"?>
#  <voms>
#    <command>COMMAND</command>+
#    <order>ORDER</order>?
#    <targets>TARGETS</targets>?
#    <lifetime>N</lifetime>?
#    <base64>B</base64>?
#    <version>V</version>?
#  </voms>
# COMMAND:  G/vo.name(/subgroup)* {All relevant} | Rrolename {All relevant} | B/vo.name(/subgroup)*:rolename | A {All} | M {List} | /vo.name(/subgroup)*/Role=rolename
#  my $msg='<?xml version="1.0" encoding = "US-ASCII"?><voms><command>G/ngs.ac.uk/ops</command><base64>1</base64><version>4</version><lifetime>43200</lifetime></voms>';
#  my $msg='<?xml version="1.0" encoding = "US-ASCII"?><voms><command>ROperations</command><base64>1</base64><version>4</version><lifetime>43200</lifetime></voms>';

  my $cmds = "";
  foreach (@FQANs) { 
    s|/Capability=[^/]+||; 
    if ( m|^(.*?)/Role=([^/]+)$| ) {$cmds .= "<command>B$1:$2</command>";}
    else { $cmds .= "<command>G$_</command>"; }
  }

  $msg='<?xml version="1.0" encoding = "US-ASCII"?><voms>'.$cmds.'<base64>1</base64><version>4</version><lifetime>'.$lifetime.'</lifetime></voms>';
  $emesg         = &Encrypt(Bin(recordLayer("17",Hex($msg))),$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher);
  my $senddata2     = Bin($emesg);
  Write($sock,$senddata2);

###############
# Read Response
  $response=Read($sock);
  if ( $response !~ /^\x17/ ) { return { Errors => ErrWarn("Expecting Encrypted Application Data, got something else"), Warnings => \@warning }; }
  my $apdata=&Decrypt($response,$KEYS{'SMAC'},$pad1sha,$pad2sha,$Sseq,$Scipher);
  my ($ac) = $apdata =~ /^.*<ac>([^<]*)<\/ac>.*$/;
  $ac =~ s/[^a-zA-Z0-9_\+=\/\[\]-]//g;
  $apdata =~ s|<error><item><number>[0-9]{4,}</number><message>([^<]*)</message></item></error>|ErrWarn(\@error,"Error from VOMS Server: \"$1\"")|ge;
  $apdata =~ s|<error><item><number>[0-9]{1,3}</number><message>([^<]*)</message></item></error>|ErrWarn(\@warning,"Warning from VOMS Server: \"$1\"")|ge;
  if ( @error > 0 ) { return { Errors => \@error, Warnings => \@warning }; }

  my $vomsac=Hex(VOMS::Lite::Base64::Decode($ac));
  $vomsac=~ s/(..)/pack('C',hex($&))/ge;
  close($sock); 
  return { AC=>encodeAC($vomsac), Warnings => \@warning };
}####Endof sub Get


sub List {
  my %context=%{ $_[0]};
  my @error; my @warning;
  if ( $] < 5.004 ) { ErrWarn(\@warning, "Perl version is old; random seed is not good"); }

  if ( ! defined $context{'Server'} )   { ErrWarn(\@error, "Server not Specified"); }
  if ( ! defined $context{'Port'} )     { ErrWarn(\@error, "Port not Specified"); }
  if ( ! defined $context{'VO'} )       { ErrWarn(\@error, "VO not Specified"); }

# IO::SOCKET::SSL may optionally use a cert and key on the file system, we too;
  if ( ! defined $context{'Cert'} && ! defined $context{'CertFile'} ) { ErrWarn(\@error, "Certificate not Specified"); }
  if ( ! defined $context{'Key'} && ! defined $context{'KeyFile'} )   { ErrWarn(\@error, "Key not Specified"); }
  if ( ! defined $context{'Cert'} && defined $context{'CertFile'} && ! -r $context{'CertFile'} ) { ErrWarn(\@error, "Certificate file unreadable"); }
  if ( ! defined $context{'Key'} && defined $context{'KeyFile'} && ! -r $context{'KeyFile'} ) { ErrWarn(\@error, "Key file unreadable"); }

  if ( @error > 0 ) { return { Errors => \@error, Warnings => \@warning }; }

  my $Server       = (($context{'Server'}   =~ /^([a-z0-9_.-]+)$/) ? $& : undef);
  my $VO           = (($context{'VO'}       =~ /^([a-z0-9_.-]+)$/) ? $& : undef);
  my $Port         = (($context{'Port'}     =~ /^([0-9]{1,5})$/ && $context{'Port'} < 65536) ? $& : 7512);

# Barf if data is not good
  if ( ! defined $Server )         { ErrWarn(\@error, "Bad VOMS server string"); }
  if ( ! defined $VO )             { ErrWarn(\@error, "Bad VO string"); }
  if ( ! defined $Port )           { ErrWarn(\@error, "Bad Port"); }

  my @certs; my $key;
  if ( ref($context{'Cert'}) eq "ARRAY" ) { @certs = @{ $context{'Cert'} }; }
  elsif ( defined($context{'Cert'}) and ref($context{'Cert'}) eq "" )   { @certs = ( $context{'Cert'} ); } #might consider a function to seperate concatenated DERs 
  elsif ( defined($context{'Cert'}) )     { ErrWarn(\@error, "Certs Argument was not a reference to an array nor a scalar"); }
  else { @certs = ( readCert($context{'CertFile'}) );}
  if ( ! @certs ) { ErrWarn(\@error, "Unable to get any user certs."); }
  foreach my $i (0 .. $#certs) { if ( $certs[$i] !~ /^\x30/s ) { ErrWarn(\@error, "Supplied certificate (\@context{'Cert'}[$i]) $certs[$i] not in DER format"); } }

  if ( defined $context{'Key'} && $context{'Key'} !~ /^\x30/s ) { ErrWarn(\@error, "Supplied Key not in DER format"); }
  if ( defined $context{'Key'} ) { $key=$context{'Key'}; }
  else { $key=readPrivateKey($context{'KeyFile'}); }
  if (! defined($key) ) { ErrWarn(\@error, "Unable to get user key."); }

  my @CAdirs;
  if ( defined $context{'CAdirs'} ) {
    if ( ref($context{'CAdirs'}) eq "ARRAY" ) { @CAdirs = @{ $context{'CAdirs'} }; }
    elsif ( ref($context{'Cert'}) eq "" )   { @CAdirs = split(':',$context{'CAdirs'}); }
    else { ErrWarn(\@error, "CAdirs Argument was not a reference to an array nor a scalar"); }
  }

  foreach my $i (0 .. $#CAdirs) { if ( ! -d $CAdirs[$i] ) { ErrWarn(\@error, "Supplied CA directory (\@context{'CAdirs'}[$i]) is not a directory"); } }

  if ( @error > 0 ) { return { Errors => \@error, Warnings => \@warning }; }

#Need CAdirs
#==========================================================
  if ( ! @CAdirs and $ENV{X509_CERT_DIR} ) {
    if ( -d $ENV{X509_CERT_DIR} and $ENV{X509_CERT_DIR} =~ /^(.*)$/) { push @CAdirs,$1; }
    else { return { Errors => ErrWarn('X509_CERT_DIR defined but it is not a directory'), Warnings => \@warning }; }
  }
  elsif ( ! @CAdirs ) {
    if ( -d $CAdir ) { push @CAdirs, $CAdir; ErrWarn(\@warning,"no CAdir specified Using $CAdir"); }
    else { return {   Errors => ErrWarn('No CAdir found'), Warnings => \@warning }; }
  }

# Get details from Cert and Key
  my %certinfo = %{ VOMS::Lite::X509::Examine( $certs[0], { SubjectDN=>"", IssuerDN=>"" }) };
  my %chain    = %{ VOMS::Lite::CertKeyHelper::buildchain( { trustedCAdirs => \@CAdirs, suppliedcerts => \@certs } ) };
  my @chain    = @{ $chain{'Certs'} };
  my $UserDN   = $chain{'EndEntityDN'};
  my $UserIDN  = $chain{'EndEntityIssuerDN'};
  my %keyinfo  = %{ VOMS::Lite::KEY::Examine( $key, { Keymodulus=>"",KeyprivateExponent=>"" }) };
  my $Keymod   = Hex($keyinfo{'Keymodulus'});
  my $Keyexp   = Hex($keyinfo{'KeyprivateExponent'});
  my $DN       = $certinfo{'SubjectDN'};
  my $IDN      = $certinfo{'IssuerDN'};

#Open a socket to the server
  my $sock = new IO::Socket::INET( PeerAddr => $Server, PeerPort => $Port, Proto => 'tcp', Type => SOCK_STREAM); 
  if ( ! defined ($sock) ) { return { Errors => ErrWarn("Unable to establish a connection to $Server:$Port"), Warnings => \@warning }; }
  $sock->autoflush(1);

#######################################
#Construct Initial Components required for SSL 
#Random
  my $hextime               = DecToHex(time);
  my $time                  = Bin($hextime);
  my $rnd = "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"; $rnd =~ s/./chr(int(rand 256))/ge;#not so good on Win32 32000 cycle reported
  my $hexrnd                = Hex($rnd);
  my $hexrandom             = $hextime.$hexrnd;
  my $hexsession            = "00";   #none - new session
  my $hexcypher_vec         = "000a";  #Ciphersuite TLS_RSA_WITH_3DES_EDE_CBC_SHA
  my $hexcypher_suits       = sprintf("%04s",DecToHex(length($hexcypher_vec)/2)).$hexcypher_vec;
  my $hexcompression_vec    = "00"; #CompressionMeth  - Use none no need data minimal + this is a lite implementation
  my $hexcompression        = sprintf("%02s",DecToHex(length($hexcompression_vec)/2)).$hexcompression_vec;
  my $hexssl_version        = "0300";
  my $hexhandshake_parts    = $hexssl_version.$hexrandom.$hexsession.$hexcypher_suits.$hexcompression;
  my $hexhello              = handShake("01",$hexhandshake_parts);
  my $clienthello           = Bin($hexhello); 
  my $hexhellorecord        = recordLayer("16",$hexhello);

#######################################
#Send Client Hello Record
  my $hellorecord           = Bin($hexhellorecord); #Client Hello Record ready to send
  Write($sock,$hellorecord);

#######################################
# Listen for ServerHello
  my $response=Read($sock);
  my $hexserverhellorecord=Hex($response);
  my $records="";
  while (length($response) > 0) {
    my $lenstr=substr($response,0,5,'');
    my $len;
    if ($lenstr =~ /^\x16\x03\x00(.)(.)/s ) { $len=ord($1)*256+ord($2); }
    else { return { Errors => ErrWarn("Malformed SSL header from server while waiting for SSL ServerHello messages"), Warnings => \@warning }; }
    $records.=substr($response,0,$len,'');
  }
  my $serverhello=$records;

#######################################
# Decode ServerHandshake Messages
  my %Hand = ParseRecords($records);

# Get the host certificate - 1, Verify VOMS cert 2, key material for pre-master key exchange later
  my $certcont = $Hand{11};
  my $lcerts = substr($certcont,0,3,'');
  my @HOSTcerts=();
  while ( length($certcont)>3 && ($lcert=substr($certcont,0,3,''))) { 
    if ($lcert =~ /(.)(.)(.)/s ) { push @HOSTcerts, substr($certcont,0,(ord($1)*65536)+(ord($2)*256)+ord($3),''); }
  }
  return { Errors => ErrWarn("No cert returned from server"), Warnings => \@warning } unless (@HOSTcerts);

# Build VOMS Server Chain Locally and check it's trusted
  my %Chain  = %{ buildchain( { trustedCAdirs => \@CAdirs, suppliedcerts => \@HOSTcerts } ) };
  my @Trust  = @{ $Chain{TrustedCA} };
  my @Errors = @{ $Chain{Errors} };
  my $EEC           =    $Chain{EndEntityCert};
  ErrWarn(\@warning, "NO CRL Check implemented");
  ErrWarn(\@warning, "NO Certificate Purpose Check implemented");
  ErrWarn(\@warning, "NO CA signing policy check implemented");
  for (my $i=0;$i < $#Errors;$i++ ) { if ( @{ $Errors[$i] } ) { ErrWarn(\@error,"Error verifying server's certificate chain (depth $i): ".join(", ",@{ $Errors[$i] })); } }
  ErrWarn(\@error,"Server's Certificate is not trusted by client") unless ($Trust[-1]);
  return { Errors => \@error, Warnings => \@warning } if (@error);

# Extract Server Cert and Key details
  my %ServerCertInfo= %{ VOMS::Lite::X509::Examine( $EEC, { SubjectDN=>"", IssuerDN=>"", Keymodulus=>"", KeypublicExponent=>"", subjectAltName=>"" }) };
  my $ServerDN=$ServerCertInfo{'SubjectDN'};
  my @SubjecyAltNames=@{ $ServerCertInfo{'subjectAltNameArray'} };
  debug("Server DN",$ServerDN);
# Check server certificate matches ! Not matching against wildcards 
  if ($ServerDN !~ m#/CN=($Server)(/|$)#) {
    my $match=0;
# Else Check Subject Alt Name matches
    foreach (@SubjecyAltNames) { debug("AltName",$_); if ($_ eq "dNSName=$Server") {$match=1; ErrWarn(\@warning,"Using SubjectAltName to Match VOMS Server Certificate")} }
    return { Errors => ErrWarn("Server Distinguished name mismatch expecting Certificate name containing CN=$Server got $ServerDN"), Warnings => \@warning } 
     if (!$match && $Server ne "localhost");
  }

# Get ServerHello bits and pieces
  my $sHello                  = $Hand{2};
  my $sHelloVer               = substr($sHello,0,2,'');
  my $sHelloTime              = substr($sHello,0,4,'');
  my $sHelloRand              = substr($sHello,0,28,'');
  my $sHelloIDlen             = ord(substr($sHello,0,1,''));
  my $sHelloSessionID         = substr($sHello,0,$sHelloIDlen,'');
  my $sHelloCypherSuite       = substr($sHello,0,2,'');
  my $sHelloCompressionMethod = substr($sHello,0,1,'');
  debug("Session ID",$sHelloSessionID);

# Get Certificate Request (request for authN)
  my $sRequest=$Hand{13};
  my $ReqTypesCount=ord(substr($sRequest,0,1,''));
  my $RSAOK=0;
  my @ReqTypes; for (my $a=0; $a<$ReqTypesCount; $a++) { push @ReqTypes,substr($sRequest,0,1,''); if ($ReqTypes[-1] eq "\x01") {$RSAOK=1;} }
  my $ReqDNNamesLen=(ord(substr($sRequest,0,1,''))*256)+ord(substr($sRequest,0,1,''));
  my $ReqDistinguishedNames=substr($sRequest,0,$ReqDNNamesLen,'');
  my @ReqASN1DN;
  while ( length($ReqDistinguishedNames) > 0 ) {
    my $DNLen=(ord(substr($ReqDistinguishedNames,0,1,''))*256)+ord(substr($ReqDistinguishedNames,0,1,''));
    push @ReqASN1DN,substr($ReqDistinguishedNames,0,$DNLen,'');
  }

# Get ServerHelloDone
  my $sHelloDone=$Hand{14};

# Check for RSA
  if ($RSAOK==0) { return { Errors => ErrWarn("Server does not support RSA AuthN"), Warnings => \@warning }; } 

# 1, Check acceptable DNs for Certificates
  my $GotCA=0;
  foreach (@ReqASN1DN) {
    my $X509subject=$_;
    my @ASN1SubjectDNIndex=ASN1Index($X509subject);
    shift @ASN1SubjectDNIndex;
    my $SubjectDN="";
    while (@ASN1SubjectDNIndex) {
      my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN)=(0,0,0,0,0);
      until ($TAG == 6 ) { ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ASN1SubjectDNIndex}; }
      my $OID=substr($X509subject,($HEADSTART+$HEADLEN),$CHUNKLEN);
      ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{shift @ASN1SubjectDNIndex};
      my $Value=substr($X509subject,($HEADSTART+$HEADLEN),$CHUNKLEN);
      $SubjectDN.="/".VOMS::Lite::CertKeyHelper::OIDtoDNattrib(ASN1OIDtoOID($OID))."=$Value";
    }
    if ($UserIDN eq $SubjectDN) { debug("MATCHED CA",$SubjectDN); $GotCA=1; } 
    else                        { debug("        CA:", $SubjectDN); }
  }
  if ( @ReqASN1DN == 0 ) { ErrWarn(\@warning, "VOMS server does not tell me what CAs are supported"); }
  elsif ( $GotCA==0 )    { return { Errors => ErrWarn("VOMS server does not support your CA"), Warnings => \@warning }; }

#########################################################
#Talk to the server again

##Construct Certificate Message Record
  my $hexcertarray =""; 
  foreach my $cert (@chain) { $hexcertarray.=sprintf("%06s",DecToHex(length($cert))).Hex($cert);}
  my $hexcertobj      = sprintf("%06s",DecToHex(length($hexcertarray)/2)).$hexcertarray;
  my $hexcertmesg     = handShake("0b",$hexcertobj);
  my $hexcertsmessagerecord=recordLayer("16",$hexcertmesg);
  my $certmesg = pack("H*", $hexcertmesg); 

##ClientKeyExchange
#PreMasterSecret
  my $prernd='X' x 46;  $prernd =~ s/./chr(int(rand 256))/ge;
  my $hexpremastersecret='0300'.Hex($prernd);

#Derive Key Material
  my %KEYS=Keygen($hexpremastersecret,$hexrandom,Hex($sHelloTime.$sHelloRand));

#Make Client Key Exchange
  my $hexEncPMSecret   = rsaencrypt($hexpremastersecret,Hex($ServerCertInfo{'KeypublicExponent'}),Hex($ServerCertInfo{'Keymodulus'}));
  my $hexClientKeyExchange  = handShake("10",$hexEncPMSecret);    #### USE ME FOR CertificateVarify
  my $hexClientKeyExchangeMessageRecord = recordLayer("16",$hexClientKeyExchange);
  my $ClientKeyExchangeMessage = Bin($hexClientKeyExchange); #### ClientCertificate for handshakemessages needs to be without record layer

#CertificateVerify
  my $Hmsgs     = $clienthello.$serverhello.$certmesg.$ClientKeyExchangeMessage;
  my $verifymac = MAC($KEYS{'MS'},$Hmsgs);

  my $hexsignedcertificateverify        = rsasign($verifymac,$Keyexp,$Keymod);
  my $hexwrappedsignedcertificateverify = sprintf("%04s",DecToHex(length($hexsignedcertificateverify)/2)).$hexsignedcertificateverify;
  my $hexcertificateverify              = handShake('0f',$hexwrappedsignedcertificateverify);
  my $certificateverify                 = Bin($hexcertificateverify);
  my $hex_ssl_certificateverifyrecord   = recordLayer("16",$hexcertificateverify);

##########################################################################
## Switch to Encrypted Session -- change_cipher_spec message
#Select algorythm for key exchange -- Must be RSA
  my $hexkeyselection="140300000101";

# Switch to tripple des (the only one I support) and send finished message

  $Hmsgs.=$certificateverify;
  my $unechexfinished=handShake("14",MAC($KEYS{'MS'},$Hmsgs."CLNT"));

#Set up the Client and Server DES3-EDE sessions
  my $Ccipher = Crypt::CBC->new( -literal_key => 1, -padding => 'null', -key => $KEYS{'CK'},  -iv => $KEYS{'CIV'}, -header => 'none', -cipher => 'DES_EDE3' );
  my $Scipher = Crypt::CBC->new( -literal_key => 1, -padding => 'null', -key => $KEYS{'SK'},  -iv => $KEYS{'SIV'}, -header => 'none', -cipher => 'DES_EDE3' );
  my $Cseq=0;
  my $Sseq=0;

  my $hex_finishedrecord = &Encrypt(Bin(recordLayer("16",$unechexfinished)),$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher);
  my $hex_finished       = $hex_finishedrecord;
  $hex_finished         =~ s/^..........//s;
  my $finished           = Bin($hex_finished);

#############################################################################
#Send Records
  Write($sock,Bin($hexcertsmessagerecord.$hexClientKeyExchangeMessageRecord.$hex_ssl_certificateverifyrecord.$hexkeyselection.$hex_finishedrecord));

#############################################################################
#Receive Response
  $response=Read($sock);
  if ( $response =~ /^\x14\x03\x00\x00\x01\x01/ ) {  $response =~ s/......//; } #Change Cypher Spec -- what we expect
  else { return { Errors => ErrWarn("Error: Expecting SSL Change Cypher Spec Message, got something else."), Warnings => \@warning }; }
  my $serverfinishedhex=Hex(&Decrypt($response,$KEYS{'SMAC'},$pad1sha,$pad2sha,$Sseq,$Scipher));

# Check response from server is a valid finished message
  $Hmsgs.=Bin($unechexfinished);
  my $unencryptedfinishedmsg = handShake("14",MAC($KEYS{'MS'},$Hmsgs."SRVR"));
  if ($unencryptedfinishedmsg ne $serverfinishedhex) { return { Errors => ErrWarn("Failed to decrypt Server Finished Message"), Warnings => \@warning }; }

######################### 
# Send no delegation byte
# predata and postdata to stop TLS CBC IV attack
  my $predata      = Bin(&Encrypt(Bin("1703000000"),$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher));
  my $msg='0';
  my $emesg        = &Encrypt(Bin(recordLayer("17",Hex($msg))),$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher);
  $senddata        = Bin($emesg);
  my $postdata     = Bin(&Encrypt(Bin("1703000000"),$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher));

  Write($sock,$predata.$senddata.$postdata);

############## 
# Send request
#<xml version="1.0" encoding = "US-ASCII"?>
#  <voms>
#    <command>COMMAND</command>+
#    <order>ORDER</order>?
#    <targets>TARGETS</targets>?
#    <lifetime>N</lifetime>?
#    <base64>B</base64>?
#    <version>V</version>?
#  </voms>
# COMMAND:  G/vo.name(/subgroup)* {All relevant} | Rrolename {All relevant} | B/vo.name(/subgroup)*:rolename | A {All} | M {List} | /vo.name(/subgroup)*/Role=rolename
#  my $msg='<?xml version="1.0" encoding = "US-ASCII"?><voms><command>G/ngs.ac.uk/ops</command><base64>1</base64><version>4</version><lifetime>43200</lifetime></voms>';
#  my $msg='<?xml version="1.0" encoding = "US-ASCII"?><voms><command>ROperations</command><base64>1</base64><version>4</version><lifetime>43200</lifetime></voms>';

  my $cmds = "<command>N</command>";

#  $msg='<?xml version="1.0" encoding = "US-ASCII"?><voms>'.$cmds.'<base64>1</base64><version>4</version><lifetime>'.$lifetime.'</lifetime></voms>';
  $msg='<?xml version="1.0" encoding = "US-ASCII"?><voms>'.$cmds.'</voms>';
  $emesg         = &Encrypt(Bin(recordLayer("17",Hex($msg))),$KEYS{'CMAC'},$pad1sha,$pad2sha,$Cseq,$Ccipher);
  my $senddata2     = Bin($emesg);
  Write($sock,$senddata2);

###############
# Read Response
  $response=Read($sock);
  if ( $response !~ /^\x17/ ) { return { Errors => ErrWarn("Expecting Encrypted Application Data, got something else"), Warnings => \@warning }; }
  my $apdata=&Decrypt($response,$KEYS{'SMAC'},$pad1sha,$pad2sha,$Sseq,$Scipher);
  my ($bitstr) = $apdata =~ /^.*<bitstr>([^<]*)<\/bitstr>.*$/;
  $bitstr =~ s/[^a-zA-Z0-9_\+=\/\[\]-]//g;
  $apdata =~ s|<error><item><number>[0-9]{4,}</number><message>([^<]*)</message></item></error>|ErrWarn(\@error,"Error from VOMS Server: \"$1\"")|ge;
  $apdata =~ s|<error><item><number>[0-9]{1,3}</number><message>([^<]*)</message></item></error>|ErrWarn(\@warning,"Warning from VOMS Server: \"$1\"")|ge;
  if ( @error > 0 ) { return { Errors => \@error, Warnings => \@warning }; }

  my $details=VOMS::Lite::Base64::Decode($bitstr,"VOMS");
  close($sock);

  my @FQANs   = grep { /^\// } split(/\n/s,$details);
  my @details = grep { /^\/$VO/ } @FQANs;
  my @others  = grep { ! /^\/$VO/ } @FQANs;
  if (@others) { my ($badvo) = $others[0] =~ m|^/([^/]+)|; push @warning => "The server seems to support a different VO: $badvo"; }
  for (my $i=0;$i<@details;$i++) {
    $details[$i] =~ s/\/(?:Capability=NULL|Role=NULL)$//;
    $details[$i] =~ s/\/(?:Capability=NULL|Role=NULL)$//;
  }

  return { FQANs=>\@details, Warnings => \@warning };
}####Endof sub List

######################################################################
sub Encrypt { #this routine modifies $_[4,5] Encrypt($rec,$MACSecret,$pad1sha,$pad2sha,$seq,$cipher)
  my ($rec,$MACSecret,$pad1sha,$pad2sha)=@_;
  debug("Encrypting",length($rec)." Bytes"); debug("MAC Secret",$MACSecret); debug("Sequence",$_[4]);
  my $type=substr($rec,0,1,'');      # First Byte is the Record Type 
  my $version=substr($rec,0,2,'');   # Next 2 bytes are SSL Version
  my $len=substr($rec,0,2,'');       # Length of the unencrypted Record
  my $seq=Bin(Seq($_[4]++)); #update this out of scope
  my $mac=sha1($MACSecret.$pad2sha.sha1($MACSecret.$pad1sha.$seq.$type.$len.$rec)); 
  my $data=$rec.$mac;  
#enc
  my $padnum=7-(length($data)%8);       ###Argh I hate padding: SSL should cope with 080808080808080808 (== 00) 
#  my $padnum=8-((length($data)+1)%8);     # How much padding is required to bring data up to blocksize
  my $pad=chr($padnum) x ($padnum+1) ;     # paddingValue x number . paddingNumber 0101, 020202, 03030303, ...
  debug("IV",$_[5]->get_initialization_vector(),1); debug("MAC",$mac,1); debug("Data",$rec); debug("Padding",$pad,1);
  my $edata=$_[5]->encrypt($data.$pad); # Encrypt data
  debug("Encrypted data",$edata,1);
  $_[5]->set_initialization_vector(substr($edata,-8,8));  #make ready for next enc.
  return recordLayer(Hex($type),Hex($edata));
}


######################################################################
sub Decrypt { #this routine modifies $_[4],[5] Decrypt($rec,$MACSecret,$pad1sha,$pad2sha,$seq,$cipher) 
  my ($rec,$MACSecret,$pad1sha,$pad2sha)=@_;
#unpack
  debug("Decrypting",length($rec)." bytes"); debug("Encrypted data",$rec,1); debug("MAC Secret",$MACSecret,1); debug("Sequence",$_[4]);

  my $data="";

#Loop over all Records in $rec Allow for openssl's defence against TLS CBC IV attack
  while ($rec) {
    my $type=substr($rec,0,1,''); my $version=substr($rec,0,2,''); my $recordlength=substr($rec,0,2,'');
    debug("Message type",$type); debug("version",$version); debug("record length",$recordlength);
    my @rl = $recordlength =~ /(.)(.)/; my $rl=ord($rl[0])*256+ord($rl[1]);
    debug("RL Decimal",$rl);
    my $minirec=substr($rec,0,$rl,'');
  #decrypt
    my $minidata=$_[5]->decrypt($minirec);
  #Update
    my $iv=substr($minirec,-8,8);
    $_[5]->set_initialization_vector($iv);
  #unpad -- ought to be this but have seen examples otherwise...
  #... 0707070707070707, 06060606060606, 050505050505, 0404040404, 03030303, 020202, 0101 -- SSL
  # 01, 0202, 030303,... -- (PKCS#5, rfc2898)
  # openssl has option for random padding / no padding - have seen VOMS server use both :-S
  # spec says we can have up to 255 bytes of padding if these are random we'd have to assume padding is always present
  # our hands are tied because these are not selfconsistant -- so:
  # If padlen byte is 0x01 - 0x08 treat as random/SSL padding, otherwise assume SSL padding and rely upon xml message always ending in '>' i.e. 0x3e and not 0x01-0x08  
    my $padchar=substr($minidata,-1,1,'');
    my $padlen=ord($padchar);
    my $pad;
    if ( ( $padlen <= 8 && $padlen > 0 ) or ( $padlen > 8 && $minidata =~ /${padchar}{$padlen}$/s ) ) { 
      $pad=substr($minidata,(0-$padlen),$padlen,''); 
      debug("Depadded","$padlen (+1) bytes"); debug("Padding",$pad,1);
    }
    else { $minidata.=$padchar; }
  #get mac
    my $mac=substr($minidata,-20,20,'');
  #verify
    my $len=Bin(sprintf("%04s",DecToHex(length($minidata))));
    my $seq=Bin(Seq($_[4]++));
    my $calcmac=sha1($MACSecret.$pad2sha.sha1($MACSecret.$pad1sha.$seq.$type.$len.$minidata));
    debug("IV",$iv); debug("MAC expected",$mac,1); debug("MAC derived",$calcmac,1); debug("Data",$minidata);
    $data.=$minidata;
  }
  return ($calcmac eq $mac)?$data:undef;
}


1;

__END__

=head1 NAME

VOMS::Lite::VOMS - Perl extension for gLite VOMS server interaction

=head1 SYNOPSIS

  use VOMS::Lite::VOMS;

  $ref = VOMS::Lite::VOMS::Get( { Server => "voms.ngs.ac.uk", 
                                    Port => 15010, 
                                   FQANs => [ "ngs.ac.uk", "ngs.ac.uk/Role=Operations" ],
                                Lifetime => 86400,
                                  CAdirs => "/path/to/CA/certificates",
                                    Cert => [ $DERCert, 
                                              $DERCertSigner, 
                                              $DERCertSignerSigner, ... ], 
                                     Key => $DERKey } );

  $AC       = ${ $ref }{'ac'};             # Contains PEM Encoded Attribute Certificate
  @Errors   = @{ ${ $ref }{'Errors'} };    # An error if encountered will stop the processing
  @Warnings = @{ ${ $ref }{'Warnings'} };  # A warning is not fatal and if no error occurs ${ $ref }{'ac'} will be set


  VOMS::Lite::VOMS::Server - Now Implemented but experimental and undocumented


=head1 DESCRIPTION

  Lightweight library to obtain a VOMS attribute certificate from a VOMS server (NOT the VOMS-Admin-Server).

  Input parameters:
    Server      Scalar: Fully Quallified Server Name (It's certificate commonName will be checked aganist this)
    Port        Scalar: The port where the vomsd for this VO is running 
                usually something like 15 thousand and something
    FQANs       Reference to an array: Fully Qualified Attribute Names
    Lifetime    Scalar: Number of seconds to ask the VOMS server to issue the AC for
    CAdirs      Scalar: ':' delimited paths to CA certificates/signers
           -or- Reference to array of paths to CA certificates/signers
    Cert        Scalar: DER formatted certificate/proxy certificate
           -or- Reference to array: DER formatted certificates/proxy certificates
    Key         Scalar: DER formatted Private Key

    CertFile and KeyFile may be specified instead of Cert and Key 
    in which case these must be PEM formatted.

  Returns a reference to a hash containing
    ac          Scalar: PEM encoded Attribute certificate
    Warnings    Reference to an array: warnings encountered
    Errors      Reference to an array: Errors encountered

  For deep Debugging set
    $VOMS::Lite::VOMS::DEBUG='yes';

=head2 EXPORT

None.

=head1 Also See

https://twiki.cnaf.infn.it/cgi-bin/twiki/view/VOMS/VOMSProtocol
(NB Command "M" should read "N")
http://glite.cvs.cern.ch/cgi-bin/glite.cgi/org.glite.security.voms

RFC3281 and the VOMS Attribute Specification document from the OGSA Athuz Workin
g Group of the Open Grid Forum http://www.ogf.org.
Also see gLite from the EGEE.

RFC3548 for Base64 encoding

This module was originally designed for the JISC funded SARoNGS project at developed at 
The University of Manchester.
http://www.rcs.manchester.ac.uk/projects/shebangs/


=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
