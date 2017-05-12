package VOMS::Lite::MyProxy;

use VOMS::Lite::PEMHelper qw(readCert readAC readPrivateKey writeCert writeKey);
use VOMS::Lite::PROXY;
use VOMS::Lite::REQ;
use IO::Socket::SSL;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

$VERSION = '0.20';

END{
  if ( -e "/tmp/mpcertfile.$<.$$" ) { unlink("/tmp/mpcertfile.$<.$$") };
  if ( -e "/tmp/mpkeyfile.$<.$$" ) { unlink("/tmp/mpkeyfile.$<.$$") };
}

sub Get {
  my %context=%{ $_[0]};
  my @error; my @warning;

  if ( ! defined $context{'Server'} )   { push @error, "VOMS::Lite::MyProxy::Get: Server not Specified"; }
  if ( ! defined $context{'Username'} ) { push @error, "VOMS::Lite::MyProxy::Get: Username not specified"; }
  if ( ! defined $context{'Password'} ) { push @error, "VOMS::Lite::MyProxy::Get: Password not Specified"; }
  if ( $#error > 0 ) { return { Errors =>\@error }; }

  my $Server       = (($context{'Server'}   =~ /^([a-z0-9_.-]+)$/) ? $& : undef);
  my $Port         = (($context{'Port'}     =~ /^([0-9]{1,5})$/ && $context{'Port'} < 65536) ? $& : 7512);
#  my $Username     = (($context{'Username'} =~ /^([\/A-Za-z0-9_.= \@-]+)$/) ? $& : undef);   # [^\n]+
  my $Username     = (($context{'Username'} =~ /^([^\n]+)$/) ? $& : undef);   # Protocol does not specify what can be a username except implicit \n
  my $Password     = (($context{'Password'} =~ /^([^\n]{6,})$/) ? $& : undef);
  my $Lifetime     = 43200; # default 12 hours
  my $Bits         = 512;   # default 512 bits
  if (defined $context{'Lifetime'}) {
    $Lifetime      = ( ( $context{'Lifetime'} =~ /^([0-9]{1,10})$/ && $context{'Lifetime'} < 1000000001 ) ? $& : undef);
  }
  if (defined $context{'Bits'}) {
    $Bits      = (($context{'Bits'}     =~ /^(512|1024|2048|4096)$/) ? $1 : undef);
  }
  my $Quiet        = ((defined $context{'Quiet'}) ? 1 : undef);

# IO::SOCKET::SSL may optionally use a cert and key on the file system;
  if ( defined $context{'Cert'} && ! defined $context{'CertFile'} ) {
                                          writeCert("/tmp/mpcertfile.$<.$$",$context{'Cert'});
                                          $context{'CertFile'} = "/tmp/mpcertfile.$<.$$"; }
  if ( defined $context{'Key'} && ! defined $context{'KeyFile'} )  {
                                          writeKey("/tmp/mpkeyfile.$<.$$",$context{'Key'},"");
                                          $context{'KeyFile'}  = "/tmp/mpkeyfile.$<.$$"; }

# Barf if data is not good
  if ( ! defined $Server )         { push @error, "VOMS::Lite::MyProxy::Get: Bad MyProxy server string"; }
  if ( ! defined $Username )       { push @error, "VOMS::Lite::MyProxy::Get: Bad Username"; }
  if ( ! defined $Password )       { push @error, "VOMS::Lite::MyProxy::Get: Password too short"; }
  if ( ! defined $Lifetime )       { push @error, "VOMS::Lite::MyProxy::Get: Lifetime is bad"; }
  if ( ! defined $Bits )           { push @error, "VOMS::Lite::MyProxy::Get: Keysize is bad"; }

  if ( defined $context{'CertFile'} && ! defined $context{'KeyFile'} ) { push @error, "VOMS::Lite::MyProxy::Get: SSL Certificate specified without Key"; } 
  if ( defined $context{'KeyFile'} && ! defined $context{'CertFile'} ) { push @error, "VOMS::Lite::MyProxy::Get: SSL Key specified without Certificate"; } 
  if ( defined $context{'CertFile'} && ! -r $context{'CertFile'} ) { push @error, "VOMS::Lite::MyProxy::Get: SSL Certificate specified but file not readable"; }
  if ( defined $context{'KeyFile'}  && ! -r $context{'KeyFile'} )  { push @error, "VOMS::Lite::MyProxy::Get: SSL Key specified but file not readable"; }

  if ( @error > 0 ) { return { Errors =>\@error }; }

### Open SSL connection to MyProxy Server #######################################

  my $client;
  if ( defined $context{'CertFile'} && defined $context{'KeyFile'} ) {
    $client = IO::Socket::SSL->new(PeerAddr => "$Server:$Port",
                                SSL_version => 'SSLv3',
                              SSL_cert_file => $context{'CertFile'},
                               SSL_key_file => $context{'KeyFile'},
                               SSL_use_cert => 1,
                                SSL_ca_path => "/etc/grid-security/certificates",
                            SSL_verify_mode => 0x07);
  }
  else {
    $client = IO::Socket::SSL->new(PeerAddr => "$Server:$Port",
                                SSL_version => 'SSLv3',
                                SSL_ca_path => "/etc/grid-security/certificates",
                            SSL_verify_mode => 0x07);
  }

# Barf if connection failed
  if ( ! $client ) { return { Errors =>[ "VOMS::Lite::MyProxy::Get: Couldn't establish secure connection with MyProxy Server $Server:$Port" ] }; }

# Barf if server is not the authentic server
  if ( $client->peer_certificate("subject") !~ /\/CN=(?:host\/|myproxy\/)?$Server(?:\/|$)/ ) {
    return { Errors =>[ "VOMS::Lite::MyProxy::Get: MyProxy Server $Server doesn't match certificate name ".$client->peer_certificate("subject") ] };
  }

#### Send put request ###########################################################
  $client->print("0VERSION=MYPROXYv2\nCOMMAND=0\nUSERNAME=$Username\nPASSPHRASE=$Password\nLIFETIME=$Lifetime\n");
  $client->print("\0");

#### Read Response ##############################################################
  my $response="";
  my $max=0;
  my $expect="VERSION=MYPROXYv2\n";
  while ( $expect =~ /^$response/ && $response ne $expect ) { 
    $response.=$client->getc(); 
  }
  if ( $expect !~ /^$response/ ) { 
    for($i=length($response);$i<20;$i++) {$response.=$client->getc();}
    close $client; 
    return { Errors =>[ "VOMS::Lite::MyProxy::Get: MyProxy server Version is not 2. The server responded: \"$response\"" ] } 
  };

  until ( substr($response,-1,1) eq "\0" || $max++ > 10000) { 
    $response.=$client->getc(); 
  }
  if ( $response !~ /VERSION=MYPROXYv2\n/ ) {
    close $client;
    return { Errors =>[ "VOMS::Lite::MyProxy::Get: MyProxy server Version is not 2: $response" ] };
  } elsif ( $response !~ /VERSION=MYPROXYv2\nRESPONSE=0/ ) {
    close $client;
    return { Errors =>[ "VOMS::Lite::MyProxy::Get: MyProxy didn't like me: $response" ] };
  }

#### Create Request ##############################################################
  my %Req;
  if ( ! defined $Quiet ) {   %Req =  %{ VOMS::Lite::REQ::Create( { Bits => $Bits, DN => ["CN=NO NAME SPECIFIED"] } ) }; }
  else                    { %Req =  %{ VOMS::Lite::REQ::Create( { Bits => $Bits, DN => ["CN=NO NAME SPECIFIED"], Quiet => 1 } ) }; }

  if ( defined $Req{'Errors'} ) {
    close $client;
    return { Errors =>[ "VOMS::Lite::MyProxy::Get: Failed to create a certificate request: @{ $Req{'Errors'} }" ] };
  }

#### Delegate Proxy #############################################################
  my $data=$Req{'Req'};
  $response="";
  $client->print("$data");
  $client->print("\x00");

### Wait for cert chain #########################################################
  my $chainlen=ord($client->getc()); # first byte is the number of certs to expect (0-255)
  my $chainindex=0;
  my @chain=();
  while ( $chainlen > $chainindex ) { # loop through returned certs
    my $len=0; my $sublen; my $cert="";
    while ($len==0) { # Loop to get length of DER Cert
      $cert.=$client->getc();
      if    ( $cert =~ /^\x30([\0-\x7f])$/s )   { $len=ord($1);}                                # length < 128 !unlikely!
      elsif ( !defined($sublen) && $cert =~ /^\x30([\x80-\xff])$/s ) { $sublen=(ord($1)-128); } # length > 127, we get length-header length
      elsif ( $cert !~ /^\x30/ ) { # This is an error all DER certs start with \x30
        $client->read($response,1024); 
        close $client;
        return { Errors =>[ "VOMS::Lite::MyProxy::Get: Expecting DER encoded cert recieved something else: \"$cert$response\"" ] }; }
      if ( defined $sublen && $cert =~ /^\x30[\x80-\xff](.{$sublen})$/s ) {
        $_=$1; s/./$len+=(256**(--$sublen)*ord($&))/ges;
      }
    }
    my $buffer;
    $client->read($buffer,$len);
    $cert.=$buffer;
    $chain[$chainindex]=$cert;
    $chainindex++;
  }

  $client->read($response,1024);
  close $client;

  if    ( $response eq "" )           { push @warning,"VOMS::Lite::MyProxy::Get: No Response message after receiving $chainlen certificates"; }
  elsif ( $response !~ /RESPONSE=0/ ) { return { Errors =>[ "VOMS::Lite::MyProxy::Get: Failed to get cert from MyProxy" ] }; }

  return { CertChain=>\@chain, Key=>$Req{Key}, Warnings=>\@warning };
}

#################################################################################

sub Init {
  my %context=%{ $_[0]};
  my @error; my @warning;

#### Check Input ################################################################
  if ( ! defined $context{'Server'} )   { push @error, "VOMS::Lite::MyProxy::Init: Server not Specified"; }
  if ( ! defined $context{'CertFile'} && ! defined $context{'Cert'}) 
                                        { push @error, "VOMS::Lite::MyProxy::Init: Certificate not Specified"; }
  if ( ! defined $context{'KeyFile'} && ! defined $context{'Key'})  
                                        { push @error, "VOMS::Lite::MyProxy::Init: Key not Specified"; }
  if ( ! defined $context{'Username'} ) { push @error, "VOMS::Lite::MyProxy::Init: Username not specified"; }
  if ( ! defined $context{'Password'} ) { push @error, "VOMS::Lite::MyProxy::Init: Password not Specified"; }

  if ( @error > 0 ) { return { Errors => \@error }; }

  my $Lifetime     = (($context{'Lifetime'} =~ /^([0-9]+)$/)       ? $& : 86400);
  my $ReleaseLife  = (($context{'ReleaseLifetime'} =~ /^([0-9]+)$/)       ? $& : 32400);
  my $Server       = (($context{'Server'}   =~ /^([a-z0-9_.-]+)$/) ? $& : undef);
  my $Port         = (($context{'Port'}     =~ /^([0-9]{1,5})$/ && $context{'Port'} < 65536) ? $& : 7512);
#  my $Username     = (($context{'Username'} =~ /^([A-Za-z0-9_.\%\@-]+)$/) ? $& : undef);
  my $Username     = (($context{'Username'} =~ /^([^\n]+)$/) ? $& : undef);
  my $Password     = (($context{'Password'} =~ /^([^\n]{6,})$/) ? $& : undef);
  my $pathlen      = ((( defined  $context{'PathLength'} && $context{'PathLength'} =~ /^([0-9]+)$/s) ) ? $& : undef);
  my $AC           = (($context{'AC'}       =~ /^(\060.+)$/s) ? $& : undef);
  if ( ! defined $context{'Username'} ) { $Username = ${VOMS::Lite::PROXY::Examine($context{'Cert'},{SubjectDN=>""})}{'SubjectDN'}; }

# IO::SOCKET::SSL needs a cert on the file system; VOMS::Lite needs a cert in memory
  if ( ! defined $context{'CertFile'} ) { writeCert("/tmp/mpcertfile.$<.$$",$context{'Cert'});
                                          $context{'CertFile'} = "/tmp/mpcertfile.$<.$$"; } 
  if ( ! defined $context{'KeyFile'} )  { writeKey("/tmp/mpkeyfile.$<.$$",$context{'Key'},""); 
                                          $context{'KeyFile'}  = "/tmp/mpkeyfile.$<.$$"; } 
  if ( ! defined $context{'Cert'} )     { $context{'Cert'}     = readCert($context{'CertFile'}); }
  if ( ! defined $context{'Key'} )      { $context{'Key'}      = readPrivateKey($context{'KeyFile'}); }

# Barf if data is not good
  if ( ! -r $context{'CertFile'} ) { push @error, "VOMS::Lite::MyProxy::Init: Certificate file not readable"; }
  if ( ! -r $context{'KeyFile'} )  { push @error, "VOMS::Lite::MyProxy::Init: Key file not readable"; }
  if ( ! defined $Server )         { push @error, "VOMS::Lite::MyProxy::Init: Bad MyProxy server string"; }
#  if ( ! defined $Username )       { push @error, "VOMS::Lite::MyProxy::Init: Bad Username"; }
  if ( ! defined $Password )       { push @error, "VOMS::Lite::MyProxy::Init: Password too short"; }
  if ( $context{'Key'}  !~ /^(\060.+)$/s ) 
                                   { push @error, "VOMS::Lite::MyProxy::Init: Key is not in correct (DER) format"; }
  if ( $context{'Cert'}  !~ /^(\060.+)$/s ) 
                                   { push @error, "VOMS::Lite::MyProxy::Init: Cert is not in correct (DER) format"; }
  if ( @error > 0 ) { return { Errors => \@error }; }

# Some warnings
  if ( $ReleaseLife > $Lifetime ) { push @warning, "VOMS::Lite::MyProxy::Init: The requested release policy lifetime (${ReleaseLife}s) is greater than the delegated proxy lifetime (${Lifetime}s)."; }

### Open SSL connection to MyProxy Server #######################################
  my $client = IO::Socket::SSL->new(PeerAddr => "$Server:$Port",
                                 SSL_version => 'SSLv3',
                               SSL_cert_file => $context{'CertFile'},
                                SSL_key_file => $context{'KeyFile'},
                                SSL_use_cert => 1,
                                 SSL_ca_path => "/etc/grid-security/certificates",
                             SSL_verify_mode => 0x07);

# Barf if connection failed
  if ( ! $client ) { return { Errors => [ "VOMS::Lite::MyProxy::Init: Couldn't establish secure connection with MyProxy Server $Server:$Port $context{'CertFile'} $context{'KeyFile'}" ] }; }
 
# Barf if server is not the authentic server
  if ( $client->peer_certificate("subject") !~ /\/CN=(?:host\/|myproxy\/)?$Server(?:\/|$)/ ) {
    return { Errors => [ "VOMS::Lite::MyProxy::Init: MyProxy Server $Server doesn't match certificate name ".$client->peer_certificate("subject") ] };
  }
    
#### Send put request ###########################################################
  $client->print("0VERSION=MYPROXYv2\nCOMMAND=1\nUSERNAME=$Username\nPASSPHRASE=$Password\nLIFETIME=$ReleaseLife\n");
  $client->print("\0");

#### Read Response ##############################################################
  my $response="";
  my $req="";
  until ($response =~ /\0/ ) { $response.=$client->getc(); }
  if ( $response =~ /VERSION=MYPROXYv2\nRESPONSE=0/ ) {
    my $len=0; my $sublen;
    while ($len==0) { # Loop to get length of DER Request
      $req.=$client->getc();
      if ( $req =~ /^\x30([\0-\x7f])$/ ) { $len=ord($1);}
      elsif ( $req =~ /^\x30([\x80-\xff])$/ ) { $sublen=(ord($1)-128); }
      if ( defined $sublen && $req =~ /^\x30[\x80-\xff](.{$sublen})$/ ) {
        $_=$1; s/./$len+=(256**(--$sublen)*ord($&))/ges;
      }
    }
    my $buffer;
    $client->read($buffer,$len);
    $req.=$buffer;
  } elsif ( $response !~ /VERSION=MYPROXYv2\n/ ) {
    close $client;
    return { Errors => [ "VOMS::Lite::MyProxy::Init: MyProxy server Version is not 2: $response" ] } ;
  } else {
    close $client;
    return { Errors => [ "VOMS::Lite::MyProxy::Init: MyProxy didn't like me: $response" ] };
  }

#### Parse the Certificate Request ##############################################
  my $ref=VOMS::Lite::REQ::Examine($req,{SubjectDN=>"", KeypublicExponent=>"", KeypublicModulus=>""});

#### Create A proxy #############################################################
  my %proxyinit=( Cert=>$context{'Cert'},
                   Key=>$context{'Key'},
                 Quiet=>1,
     KeypublicExponent=>${ $ref }{'KeypublicExponent'},
      KeypublicModulus=>${ $ref }{'Keymodulus'},
              Lifetime=>$Lifetime, 
            PathLength=>$pathlen
                );

  if ( defined $AC ) { $proxyinit{AC} = $AC; }
    
  my %proxy = %{ VOMS::Lite::PROXY::Create( \%proxyinit ) };

  if ( defined $proxy{'Errors'} ) {
    close $client;
    return { Errors => [ "VOMS::Lite::MyProxy::Init: Failed to create a proxy: @{ $proxy{'Errors'} }" ] };
  }

#### Delegate Proxy #############################################################
  my $data="\x02".$proxy{'ProxyCert'}.$context{'Cert'};
  $response="";
  $client->print("$data");
  $client->read($response,1024);
  close $client;

  if ( $response !~ /RESPONSE=0/ ) { return { Errors => [ "VOMS::Lite::MyProxy::Init: Delegation failed:$response" ] }; }
  return { Username => $Username, Password => $Password, Lifetime => $Lifetime, ReleaseLifetime => $ReleaseLife, Server => $Server, Port => $Port, ProxyCert => $proxy{'ProxyCert'} };
}

1;

__END__

=head1 NAME

VOMS::Lite::MyProxy - Perl extension for MyProxy server interaction

=head1 SYNOPSIS

  use VOMS::Lite::MyProxy;
  use VOMS::Lite::REQ;
  %Result= %{ VOMS::Lite::MyProxy::Init(
                {
                    Server => "myproxy.grid-support.ac.uk",
                  CertFile => "/home/fred/.globus/usercert.pem",
                   KeyFile => "/home/fred/.globus/userkey.pem",
                  Username => "Freds7DayCert",
                  Password => "A Good Secret"
                }
              )
            };

  %Proxy= %{ VOMS::Lite::MyProxy::Get(
               {
                   Server => "myproxy.grid-support.ac.uk",
                 Username => "Freds7DayCert",
                 Password => "A Good Secret"
               }
             )
           };
  
=head1 DESCRIPTION

VOMS::Lite::MyProxy contains two subroutines, Get which offers a simplistic 
myproxy-get-delegation, and Init which offers a simplistic myproxy-init operation.

i.e. 'Init' delegates a proxy to a myproxy server and 'Get' asks the server to 
delegate a proxy to it.

=head2 VOMS::Lite::MyProxy::Init

VOMS::Lite::MyProxy::Init takes one argument, an anonymous hash
containing all the relevant information required to delegate a Proxy to a MyProxy Server.

  In the Hash the following scalars should be defined:
  'Server'   the myproxy server's FQDN e.g. myproxy.grid-support.ac.uk
  'CertFile' the path to the file containing the certificate to be delegated
  'KeyFile'  the path to the file containing the private key associated with the certificate
  'Username' the username to identify the delegated credential on the MyProxy server
  'Password' the passphrase to protect the delegated credential on the MyProxy server

    Optionally 'Cert' and 'Key' can be specified instead of CertFile and KeyFile 
    where these scalars contain the DER encoded certificate and key respectively.

  The following may also be defined

  'Lifetime' the lifetime in seconds that the delegated credential is to have.
  'AC' a DER encoded Attribute Certificate to place within the proxy certificate.

The return value is a reference to a hash containing
   Username, Password, Lifetime, Server, Port,
   Warnings => Reference to an array (A proxy will be delegated despite warnings)
   Errors => Reference to an array (It was not possible to delegate a proxy)
   ProxyCert => A copy of the GSI proxy certificate delegated to the MyProxy Server DER encoded

=head2 VOMS::Lite::MyProxy::Get

VOMS::Lite::MyProxy::Init takes one argument, an anonymous hash
containing all the relevant information required to delegate a Proxy to a MyProxy Server.

  In the Hash the following scalars should be defined:
  'Server'   the myproxy server's FQDN e.g. myproxy.grid-support.ac.uk
  'CertFile' the path to the file containing the certificate to be delegated
  'KeyFile'  the path to the file containing the private key associated with the certificate
  'Username' the username to identify the delegated credential on the MyProxy server
  'Password' the passphrase to protect the delegated credential on the MyProxy server

    Optionally 'Cert' and 'Key' can be specified instead of CertFile and KeyFile 
    where these scalars contain the DER encoded certificate and key respectively.

  The following may also be defined

  'Lifetime' the lifetime in seconds that the delegated credential is to have.
  'AC' a DER encoded Attribute Certificate to place within the proxy certificate.

The return value is a reference to a hash containing

   CertChain     a reference to an array containing the certificate chain DER encoded
   Key           the DER encoded Key
   Warnings      a reference to an array containing any warnings
   Errors        a reference to an array containing any errors.  
                 If there were errors there will be no CertChain or Key

=head2 EXPORT

None by default;  

=head1 SEE ALSO

GFD-E.054 The MyProxy Protocol http://www.gridforum.org/documents/GFD.54.pdf 

The MyProxy Website http://grid.ncsa.uiuc.edu/myproxy/

This module was originally designed for the SHEBANGS and SARoNGS project at The University of Manchester.
http://www.rcs.manchester.ac.uk/projects/shebangs/
http://www.rcs.manchester.ac.uk/projects/sarongs/

Mailing list, SARONGS-DISCUSS@jiscmail.ac.uk

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
