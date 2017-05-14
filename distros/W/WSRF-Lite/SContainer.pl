#! /usr/bin/env perl  
#
#
# COPYRIGHT UNIVERSITY OF MANCHESTER, 2003
#
# Author: Mark Mc Keown
# mark.mckeown@man.ac.uk
#
# LICENCE TERMS
#
# WSRF::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#
#
# Secure version of the Container script - uses SSL
#


use WSRF::Lite;
use Sys::Hostname::Long;
use WSRF::SSLDaemon;
use POSIX ":sys_wait_h";

$ENV{'TZ'} = "GMT";

#timeout for clients that want to keep an open tcp connection
my $TIMEOUT = "120";

if ( defined($ENV{'WSRF_SOCKETS'}) )
{
 $WSRF::Constants::SOCKETS_DIRECTORY = $ENV{'WSRF_SOCKETS'} ;
}       

if ( defined($ENV{'WSRF_DATA'}) )
{
 $WSRF::Constants::Data = $ENV{'WSRF_DATA'} ;
}       
    

if ( ! -d $WSRF::Constants::SOCKETS_DIRECTORY )
{ 
   die "Directory $WSRF::Constants::SOCKETS_DIRECTORY does not exist\n"; 
}

if ( ! -d $WSRF::Constants::Data )
{
  die "Directory $WSRF::Constants::Data does not exist\n";
}  
  

my $port = 50000;

my ($hostname);
while ( my $arg = shift @ARGV )
{
   if( $arg =~ m/-p/o)
   {
      $port = shift @ARGV;
      die "No Port number provided with -p option\n" unless defined $port;
      die "\"$port\" does not look like a port number\n" unless ( $port =~ /\d+/o );
   }
   elsif ( $arg =~ m/-h/o )
   {
      $hostname = shift @ARGV;
      die "No hostname provided with -h option\n" unless defined $hostname;    
   }
}

$hostname = Sys::Hostname::Long::hostname_long() unless defined $hostname;


# REAPER kills of stry children.
# this REAPER is designed to be used with Perl 5.8 though
# it should still work with Perl 5.6
sub REAPER {
  local $!;
  waitpid(-1,0);
  $SIG{CHLD} = \&REAPER;  # still loathe sysV
}
$SIG{CHLD} = \&REAPER;



#Check that the path to the Grid Service Modules is set
if ( !defined($ENV{'WSRF_MODULES'}) )
{
  die "Enviromental Variable WSRF_MODULES not defined";
}


#Not sure if we need to set this!! 
$ENV{SSL}="TRUE";


#Accept Proxies - later versions of OpenSSL are ment to
#accept proxies, I haven't seen this work :-(
$ENV{'OPENSSL_ALLOW_PROXY'} = "True";


   #create the Service Container - just a Web Server
   #Certificate information is provided here - could
   #use a personal certificate
   my $d = WSRF::SSLDaemon->new(
        LocalPort => $port,
  	Listen => SOMAXCONN, 
       	Reuse => 1,
        SSL_key_file => '/home/zzcgumk/.globus/hostkey.pem',
        SSL_cert_file => '/home/zzcgumk/.globus/hostcert.pem',
	SSL_ca_path => '/etc/grid-security/certificates/',
	SSL_ca_file => '/etc/grid-security/certificates/01621954.0',
	SSL_verify_mode => 0x01 | 0x02 | 0x04
    ) || do { print "Socket Error: Cannot create Socket\n"; exit; };
 

   #Store the Container Address in the ENV variables - child
   #processes can then pick it up and use it
   $ENV{'URL'} =  "https://".$hostname.":".$port."/";

   print "\nContainer Contact Address: ".$ENV{'URL'}."\n";

   #SSLDaemon ISA IO::Socket::SSL so treat like a socket
   #my $client = $d->accept || $!{EINTR}
   while ( 1 ) {   #wait for client to connect
    my $client = $d->accept;
    if ( defined $client )
    {  
      print "$$ Got Connection\n";
      if (my $pid = fork){  #fork a process to deal with request
        print "$$ Parent forked\n"; #parent should go back to accept now
	$client->close( SSL_no_shutdown => 1 ); 
	undef $client;
	print "$$ Going back to accept\n";
      } 
      elsif (defined($pid) )  #child
      {           
        print "$$ Child created ".scalar(localtime(time))."\n";
	print "$$ Connection Accepted\n";
	#Check for client certificate and set ENV variables
	my $cert = $client->dump_peer_certificate();
        my($DN,$issuer) = split( /\n/, $cert);
        $DN =~ s/Subject Name: //o;
        $issuer =~ s/Issuer  Name: //o;
        print "$$ Client DN= $DN\n";
	print "$$ Client Issuer DN= $issuer\n";
        $ENV{SSL_CLIENT_DN} = $DN;
        $ENV{SSL_CLIENT_ISSUER} = $issuer;
        while ( my $r = $client->get_request )
        {	
          my $crap = alarm 0;		
	  my $resp = WSRF::Container::handle($r,$client);	
          my $result = $client->send_response($resp);
	  print "$$ Sent Client response $result\n";
	  alarm($TIMEOUT);
        }
	print "$$ Closing Socket ". $d->close." $?\n";
        undef ($d);
        $client->close;
	undef ($client);
	print "$$ Exiting\n"; 
        exit;
      }    
      else
      {  #fork failed
         print "$$ fork failed\n";
      }
    }  
    else
    {
       next if $!{EINTR}; # just a child exiting, go back to sleep.
    } 
      	   
  }





