package VOMS::Lite::PEMHelper;

use 5.004;
use strict;
use MIME::Base64 qw(encode_base64 decode_base64);
use File::Copy qw(move);

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
%EXPORT_TAGS = ( );
@EXPORT_OK = qw( encodeCert writeAC encodeAC readAC readCert decodeCert writeKey writeCert writeCertKey readPrivateKey );
@EXPORT = ( );
$VERSION = '0.20';

################################################################

sub writeAC {  #writes a PEM formatted AC 
# Two arguments (Path to store AC and AC data as a string of chars)
  my ($file,$data)=@_;
#  my $umasksave=umask(0022);  #ACs are not private key material
#  if ( umask() != 0022 ) { die "Can't umask 0022\n"; }
  if ( -e $file ) { move($file,"$file.old"); } #move old file away
  open(AC,">$file") || die "Can't create AC file";
  print AC &encodeAC($data);
  close(AC);
#  umask($umasksave);
  return;
}

################################################################

sub encodeAC {
  return encodeCert(@_,"ATTRIBUTE CERTIFICATE");
}

################################################################

sub readAC {  #Returns BER with AC in it
  my $file=shift;
  return readCert($file,"ATTRIBUTE CERTIFICATE");
}

################################################################

sub readCert {  #Returns BERs with CERTs in them
# One arguement (path to cert file);
  my $file=shift;

  my $type=shift;
  if ( ! defined($type) ) { $type="CERTIFICATE"; }
  $type =~ y/a-z/A-Z/;
  $type =~ s/[^A-Z0-9 ]//g;

# Load and parse cert file
  my @myCertData=();
  my $Certnum=-1;
  my $read=0;
  open(CERT,"<$file") || die "Can't access Public Key file: '$file'";
  while (<CERT>) {
    my $line=$_;
    if ( $line =~ /^-----BEGIN $type-----\r?$/ ) {$read=1; $Certnum++; next;}
    if ( $line =~ /^-----END $type-----\r?$/ ) {$read=0;  wantarray ? next : last; }
    if ( $read==1 ) {
      if ( $line =~ /^([A-Za-z0-9+\/=]+)\r?$/ ) {$myCertData[$Certnum].=$1;}
    }
  }
  close(CERT);

  if ( $myCertData[0] eq "" ) { die "I didn't understand the format of your $type file:\n$file";}
  my @decoded=();
  foreach (@myCertData) { push(@decoded,decode_base64($_)); }
  return wantarray?@decoded:$decoded[0];
}

################################################################

sub decodeCert {
  my $type = pop;
  my $pems = join "\n",@_;
  my @ders;
  $pems =~ s|^-----BEGIN $type-----$([a-zA-Z0-9/+=\r\n]+)^-----END $type-----$|push @ders,decode_base64($1)|mge;
  return @ders;
}

################################################################

sub encodeCert {
  #my $certstr=shift;
  my $certstr="";
  my $type="CERTIFICATE";
  if ( $_[-1] !~ /^\x30/ ) { $type=pop; }
  
  $type =~ y/a-z/A-Z/;
  $type =~ s/[^A-Z0-9 ]//g;
  foreach (@_) {
    my $OpenSSLCompat=encode_base64($_,'');
    $OpenSSLCompat=~s/(.{1,64})/$&\n/g; 
    $certstr .= "-----BEGIN $type-----\n".$OpenSSLCompat."-----END $type-----\n";
  }
  return $certstr;
}

################################################################

sub writeCertKey {
# At least 3 arguements (file, public key, private key, [chain of signing certificates]);
  my $file=shift;
  my $pub=shift;
  my $pri=shift;

# Place file
  my $umasksave=umask(0077);
  
  if ( umask() != 0077 ) { 
    if ( $^O =~ /^MSWin/ ) { print STDERR "WARNING: Can't umask 0077 when writing $file\n"; }
    else                   { die "Can't umask 0077 when writing $file"; }
  }
  if ( -e $file ) { move($file,"$file.old"); } #move old file away

  open(CERTKEY,">$file") || die "Can't create file to save cert and key to.";
  print CERTKEY encodeCert($pub,"CERTIFICATE");
  print CERTKEY encodeCert($pri,"RSA PRIVATE KEY");
  foreach ( @_ ) { print CERTKEY encodeCert($_,"CERTIFICATE"); }
  close(CERTKEY);
  umask($umasksave);
  return;
}

################################################################

sub writeKey {
# At least 3 arguements (file, public key, private key, [chain of signing certificates]);
  my $file=shift;
  my $pri=shift;
  my $passwd=shift;
  my $ENCRYPTION="";

  if ( ! defined $passwd ) {
# Prompt for password
    require Term::ReadKey;
    print "I need the passphrase used to encrypt the key in \n$file\nPassphrase: ";
    my $dummy=Term::ReadKey::ReadMode('noecho');
    $passwd = Term::ReadKey::ReadLine(),
    $dummy=Term::ReadKey::ReadMode('normal');
    chomp $passwd;
    print "\n";
  }

# To encrypt or not to encrypt
  if ( $passwd ne "" ) {

# Spin up the Crypto stuff
    require Digest::MD5;
    require Crypt::DES_EDE3;

# Make Initialisation vector
    my $iv="";
    while (length($iv)<8 ) {$iv.=chr((rand(255)+1));}

# Construct DES Key from password (Munge)
    my $keysize=24;
    my $SALT=$iv;
    my $key=Digest::MD5::md5($passwd,$SALT);
    while (length($key) < $keysize) { $key .= Digest::MD5::md5($key, $passwd, $SALT);}
    $key=substr($key,0,$keysize);

# DES Padding Data as per RFC 1423 (not 1851 which adds message payload info)
    my $pad = ( 8 - (length($pri)%8) );
    my $padding=chr($pad) x $pad;
    $pri.=$padding;

# Encode Data
    my $DES = Crypt::DES_EDE3->new($key);
    my $cyphertextout="";
    while ( my $len=length($pri) ) {
      my $block=substr($pri,0,8);
      $pri=substr($pri,8);
      $block = $SALT ^ $block;
      my $cyphertext=$DES->encrypt($block);
      $SALT=$cyphertext;
      $cyphertextout.=$cyphertext;
    }

# Set PEM encryprion header
    $iv=unpack('H*',$iv);
    $iv =~ y/[a-f]/[A-F]/;
    $ENCRYPTION="Proc-Type: 4,ENCRYPTED\nDEK-Info: DES-EDE3-CBC,$iv\n\n";
    $pri=$cyphertextout;
  }

# Place file
  my $umasksave=umask(0077);

  if ( umask() != 0077 ) { 
    if ( $^O =~ /^MSWin/ ) { print STDERR "WARNING: Can't umask 0077 when writing $file\n"; }
    else                   { die "Can't umask 0077 when writing $file"; }
  }
  if ( -e $file ) { move($file,"$file.old"); } #move old file away

  open(KEY,">$file") || die "Can't create file to save cert and key to.";
  my $OpenSSLCompat=encode_base64($pri,'');
  $OpenSSLCompat=~s/(.{1,64})/$&\n/g;
  print KEY "-----BEGIN RSA PRIVATE KEY-----\n$ENCRYPTION".$OpenSSLCompat."-----END RSA PRIVATE KEY-----\n";
  close(KEY);
  umask($umasksave);
  return;
}

################################################################

sub writeCert {
# At least 3 arguements (file, public key, private key, [chain of signing certificates]);
  my $file=shift;
  my $pub=shift;
  my $type=shift;
  if ( ! defined($type) ) { $type="CERTIFICATE"; }
  $type =~ y/a-z/A-Z/;
  $type =~ s/[^A-Z0-9 ]//g;

# Place file
  if ( -e $file ) { move($file,"$file.old"); } #move old file away
  open(CERT,">$file") || die "Can't create file to save cert and key to.";
  my $OpenSSLCompat=encode_base64($pub,'');
  $OpenSSLCompat=~s/(.{1,64})/$&\n/g;
  print CERT "-----BEGIN $type-----\n".$OpenSSLCompat."-----END $type-----\n";
  close(CERT);
  return;
}


################################################################

sub readPrivateKey {  #Returns BER with Private key in it
# Two arguements (path to private key, and optional password);
  my $file=shift;
  my $passwd=shift;

# Load and parse private key file
  my ($myKeyData,$PEMV,$PEMType,$PEMEnc,$SALT)=("","","","","");
  my $read=0;
  open(KEY,"<$file") || die "Can't access Private Key file $file";
  while (<KEY>) {
    my $line=$_;
    if ( $line =~ /^-----BEGIN RSA PRIVATE KEY-----$/ ) {$read=1; next;}
    if ( $line =~ /^-----BEGIN PRIVATE KEY-----$/ ) {$read=2; next;}
    if ( $line =~ /^-----END RSA PRIVATE KEY-----$/ ) {last;}
    if ( $line =~ /^-----END PRIVATE KEY-----$/ ) {last;}
    if ( $read==1 ) {
      if ( $line =~ /^Proc-Type: ([0-9]+),(ENCRYPTED)$/ ) {$PEMV=$1; $PEMType=$2}
      elsif ( $line =~ /^DEK-Info: (.*),(.*)$/ ) {$PEMEnc=$1; $SALT=$2}
      elsif ( $line =~ /^([A-Za-z0-9+\/=]+)$/ ) {$myKeyData.=$1;}
    }
    if ( $read==2 ) {
      if ( $line =~ /^([A-Za-z0-9+\/=]+)$/ ) {$myKeyData.=$1;}
    }
  }
  close(KEY);

# Return data if it's not encrypted
  if ( $myKeyData eq "" ) { die "I didn't understand the format of your key file:\n$file";}

# Obtain and check Encryption values
  my $cyphertext=decode_base64($myKeyData);

# If "PRIVATE KEY" but not "RSA PRIVATE KEY" Parse into it
  if ( $read == 2 ) { # Unencrypted pkcs #8
    die "I didn't understand the format of your key file:\n$file";
  }

  return $cyphertext if ( $PEMType ne "ENCRYPTED" ); # Because actually it's not encrypted.
  if ( $PEMEnc ne "DES-EDE3-CBC" ) { die "I don't know how to unencrypt your key\n";}
  if ( $SALT !~ /^[a-fA-F0-9]{16}$/ ) { die "Bad Initilisation Vector (salt)'; I can't unencrypt your key!\n";}
  if ( $PEMV ne "4" ) { print STDERR "Warning: I was expecting a version 4 PEM encrypted file you gave me a Version $PEMV\nFunny things may happen!\n"; }


# Check/get password
  if ( defined $passwd && $passwd eq "" ) { return undef; } #was expecting no password so abort
  elsif ( ! defined $passwd ) {
    require Term::ReadKey;
    require Digest::MD5;
    print "I need the passphrase used to encrypt the key in \n$file\nPassphrase: ";
    my $dummy=Term::ReadKey::ReadMode('noecho');
    $passwd = Term::ReadKey::ReadLine(),
    $dummy=Term::ReadKey::ReadMode('normal');
    chomp $passwd;
    print "\n";
  }

# Reconstruct DES Key from password (Munge)
  my $keysize=24;
  $SALT=pack('H*', $SALT);
  my $key=Digest::MD5::md5($passwd,$SALT);
  while (length($key) < $keysize) { $key .= Digest::MD5::md5($key, $passwd, $SALT);}
  $key=substr($key,0,$keysize);

# Decode Data
  require Crypt::DES_EDE3;
  my $DES = Crypt::DES_EDE3->new($key);
  my $dataout="";
  while ( my $len=length($cyphertext) ) {
    my $block=substr($cyphertext,0,8);
    $cyphertext=substr($cyphertext,8);
    my $data=$SALT ^ $DES->decrypt($block);
    $SALT=$block;
    $dataout.=$data;
  }

# Remove DES Padding
  my $unpad=substr ($dataout,-1);
  if ( "$unpad" =~ /[\001-\010]/  ) { $dataout=substr($dataout,0,-ord($unpad));}
  else { die "Your passphrase didn't do it for me!\n";}

  return $dataout;
}

1;
__END__

=head1 NAME

VOMS::Lite::PEMHelper - Perl extension for decoding and encoding PEM X.509 certificates and keys.

=head1 SYNOPSIS

  use VOMS::Lite::PEMHelper qw( writeAC encodeCert encodeAC readAC readCert decodeCert writeCertKey readPrivateKey writeCert writeKey);

  # write DER AC $data as a PEM AC to file $file
  writeAC($file,$data);

  # encode DER Certificate $data as a PEM Certificate
  $cert=encodeCert($data); 

  # encode DER AC $data as a PEM AC
  $ac=encodeAC($data); 

  # read PEM AC in file $file and return DER AC 
  $data=readAC($file);

  # read PEM Certificates in file $file and return DER Certificates 
  # in array
  @certs=readCert($file);

  # read PEM Certificates in file $file and return the first as a DER 
  # Certificate
  $cert=readCert($file);

  # takes a string and/or array of PEMs followsd by a type as arguments 
  # and decodes them into an array of DERs
  @DERs=decodeCert(@PEMs,"CERTIFICATE"); 

  # take DER certificate, private key and (optionally) a chain of
  # signers and write them in PEM format to file $file
  writeCert($file, $cert);

  # take DERprivate key and write it in PEM format to file $file, 
  # encrypting with $password. If $password is undefined it will prompt 
  # for a password, if password is "" no encryption will be used.
  writeKey($file, $privateKey, $password);

  # take DER certificate, private key and (optionally) a chain of 
  # signers and write them in PEM format to file $file
  writeCertKey($file, $cert, $privateKey, @chain);

  # read in a PEM private key, prompt for a password if encrypted and 
  # return unencrypted DER private key.
  $key=readPrivateKey($file);

=head1 DESCRIPTION

VOMS::Lite::PEMHelper is primarily for internal use.  But frankly I don't mind if you use this package directly :-)

=head2 EXPORT

None by default.

By EXPORT_OK the following functions:
  writeAC
  encodeAC
  readAC
  readCert
  decodeCert
  writeCertKey
  readPrivateKey
  writeCert
  writeKey

=head1 SEE ALSO

RFC 1421 
RFC 3447

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
