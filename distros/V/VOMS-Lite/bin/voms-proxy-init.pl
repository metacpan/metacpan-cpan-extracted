#!/usr/bin/perl

use VOMS::Lite::VOMS;
use VOMS::Lite::PEMHelper qw(readCert readAC readPrivateKey writeCertKey decodeCert);
use VOMS::Lite::ASN1Helper qw(ASN1Wrap ASN1Unwrap DecToHex Hex ASN1BitStr);
use VOMS::Lite::PROXY;
#use LWP::UserAgent; #Now only loaded if required
#use HTTP::Request;

my $name=$0;
my $lname=length($name);
$name =~ s#.*/##g;
my $usage = "Usage: $name vomss://voms.server:port/VO[/Subgroup...[/Role=...[/Capability=...]]] [ -cert /path/to/cert.pem ]\n".
" " x ($lname+8). "[ -key /path/to/cert's/key.pem ]\n".
" " x ($lname+8). "[ -out /path/to/save/proxy ]\n".
" " x ($lname+8). "[ -lifetime N (hours, default 12 hours) ]\n".
" " x ($lname+8). "[ -CApath /path/to/CA/directory (to verify VOMS server against) ]\n".
" " x ($lname+8). "[ -pl N  ]\n".
" " x ($lname+8). "[ -(old|new|rfc|limited)  ]\n".
" " x ($lname+8). "[ -limited  ]\n";
" " x ($lname+8). "[ -verbose  ]\n";

my %Input;
$Input{'Type'}="Legacy";
my $lifetime=43200;
$Input{'Quiet'}="1";
my $HolderCert="$ENV{HOME}/.globus/usercert.pem";
my $HolderKey="$ENV{HOME}/.globus/userkey.pem";
my $CAPath="/etc/grid-security/certificates";
if ( defined $ENV{"X509_CERT_PATH"} && $ENV{"X509_CERT_PATH"} =~ /(.*)/ ) { $CAPath=$1; };
my $outfile="/tmp/x509up_u$<";
if ( defined $ENV{"X509_USER_PROXY"} && $ENV{"X509_USER_PROXY"} =~ /(.*)/ ) { $outfile=$1; };
my ($vomsattribfile,$pathlen);
my @VOMSURI;
my $verbose=0;

while ($_=shift @ARGV) {
  if    ( /^--?cert$/ ) {
    $HolderCert=shift @ARGV;
    die "$& requires an argument" if ( ! defined $HolderCert );
    die "cannot open certificate file $HolderCert" if ( ! -r $HolderCert );
  }
  elsif ( /^--?key$/ ) {
    $HolderKey=shift @ARGV;
    die "$& requires an argument" if ( ! defined $HolderKey );
    die "cannot open certificate file $HolderKey" if ( ! -r $HolderKey );
  }
  elsif ( /^--?CApath$/ ) {
    $CAPath=shift @ARGV;
    die "$& requires an argument" if ( ! defined $CAPath );
    die "$CAPath is not a directory" if ( ! -d $CAPath );
    die "cannot open CA directory $CAPath" if ( ! -r $CAPath );
  }
  elsif ( /^--?out$/ ) {
    $outfile=shift @ARGV;
    die "$& requires an argument" if ( ! defined $outfile );
  }
  elsif ( /^--?limited$/ )      { $Input{'Type'}="Limited"; }
  elsif ( /^--?(new|gt3)$/ )    { $Input{'Type'}="Pre-RFC"; print <<EOF;
Warning: Although a VOMS enabled proxy certificate in Pre-RFC form is valid,
         early VOMS implementations may not recognise the link between VOMS AC
         and the identity assserted by a Pre-RFC proxy certificate. 
EOF
  }
  elsif ( /^--?rfc$/ )          { $Input{'Type'}="RFC"; print <<EOF;
Warning: Although a VOMS enabled proxy certificate in RFC form is valid,
         early VOMS implementations may not recognise the link between VOMS AC
         and the identity assserted by an RFC proxy certificate.
EOF
  }
  elsif ( /^--?(old|legacy)$/ ) { $Input{'Type'}="Legacy"; }
  elsif ( /^--?(pl|pathlength)$/ ) {
    $pathlen=shift @ARGV;
    die "$& requires an argument" if ( ! defined $pathlen );
    die "Bad Pathlength argument, $& requires a positive integer" if ( $pathlen !~ /^[0-9]+$/ );
  }
  elsif ( /^--?l(ifetime)?$/ ) {
    $lifetime=shift @ARGV;
    die "$& requires an argument" if ( ! defined $lifetime );
    die "$& requires a positive numeric integer argument." if ( $lifetime !~ /^[0-9]+$/ );
  }
  elsif ( /^--?b(?:its)?$/ ) {
    my $bits=shift @ARGV;
    die "$& requires an argument" if ( ! defined $bits );
    die "$& must be a positive integer." if ( $bits !~ /^[0-9]+$/ );
    $Input{'Bits'}=$bits;
  }
  elsif ( /^vomss:\/\/.*$/ ) {
    push @VOMSURI,$&;
  }
  elsif ( /^https:\/\/.*$/ ) {
    push @VOMSURI,$&;
  }
  elsif ( /^--?v(?:erbose)?$/ )  { $Input{'Quiet'}=undef; $verbose=1; }
  elsif ( /^--?debug$/ ) { $VOMS::Lite::VOMS::DEBUG="yes"; $Input{'Quiet'}=undef; $verbose=1; }
  else { die "Unrecognised option \"$_\"\n$usage"; }
}

# Then make proxy cert
my @decodedCERTS=readCert($HolderCert);
$Input{'Cert'}=$decodedCERTS[0];
$Input{'Key'}=readPrivateKey($HolderKey);
$Input{'Lifetime'}=$lifetime;
$Input{'PathLength'}=$pathlen;

$ENV{HTTPS_CA_DIR}    = $CAPath;
$ENV{HTTPS_CERT_FILE} = $HolderCert;
$ENV{HTTPS_KEY_FILE}  = $HolderKey;
my $AC;

my %URI;
my @URI;
foreach (@VOMSURI) {
  if ( m|(vomss://[^:]+:[^/]+)(/.+)| ) {
    if ( defined $URI{$1} ) { push @{ $URI{$1}},$2; }
    else { $URI{$1}=[$2]; push @URI,"$1"; }
  } elsif ( m|https://[^:]+(?::[0-9]{1,5})?/.+| ) {
    eval "use HTTP::Request";  if ($@) { die "HTTP::Request is required for https style URIs"; }
    eval "use LWP::UserAgent"; if ($@) { die "LWP::UserAgent is required for https style URIs"; }
    push @URI,$_;
  }
}

foreach my $URI (@URI) {
  if ( $URI =~ m|vomss://([^:]+):([^/]+)| ) {
    print "Contacting $URI for ".(join(', ',@{ $URI{$URI} }))." using $HolderCert\n";
    my $ref = VOMS::Lite::VOMS::Get( { Server => "$1", 
                                         Port => $2, 
                                        FQANs => $URI{$URI},
                                     Lifetime => $lifetime,
                                       CAdirs => $CAPath,
                                         Cert => $Input{'Cert'}, 
                                          Key => $Input{'Key'} } );

    if (@{ ${ $ref }{Errors} } )   { print "Errors:\n  ".(join "\n  ", @{ ${ $ref }{Errors} }).".\n"; die "Failed to get ".join(', ',@{ $URI{$URI} }); }
    if (@{ ${ $ref }{Warnings} } and $verbose==1) { print "Warnings for $1:$2$3\n  ".(join "\n  ", @{ ${ $ref }{Warnings} }).".\n"; }
    $AC.=${ $ref }{'AC'}."\n";
  }
  elsif ( m|https://[^:]+(?::[0-9]{1,5})?/.+| ) {

   # eval test 
   # use LWP::UserAgent;
   # use HTTP::Request;


    my $req      = HTTP::Request->new( GET => $URI, HTTP::Headers->new('Accept' => "text/plain"));
    my $agent    = LWP::UserAgent->new;
    my $response = $agent->request( $req );
    print "Contacting $URI\n";
    if ( $response->is_success ) {
      $AC.=$response->content;
      if ($verbose) { print "Server responded as follows:\n$AC\n\n"; }
    } else {
      if ($verbose) { print "Server responded as follows:\n".$response->as_string; }
      die "Unable to obtain AC from $URI";
    }
  }
}

print "Creating Proxy\n";

if ( $AC ) {
  my @ACDER=decodeCert($AC,"ATTRIBUTE CERTIFICATE");
  $Input{'AC'}=join('',@ACDER);
}
else { print "Warning: No attribute certificates were obtained or generated\n"; }

my %Output = %{ VOMS::Lite::PROXY::Create(\%Input) };
if ( ! defined $Output{ProxyCert} || ! defined $Output{ProxyKey} ) {
  foreach ( @{ $Output{Errors} } ) { print "Error:   $_\n"; }
  die "Failed to create proxy";
}
foreach ( @{ $Output{Warnings} } ) { print "Warning: $_\n"; }
print "Writing Proxy to $outfile\n";
writeCertKey("$outfile", $Output{'ProxyCert'}, $Output{'ProxyKey'}, @decodedCERTS);

__END__

=head1 NAME

  voms-proxy-init.pl

=head1 SYNOPSIS

  An extension to the proxy-init.pl scrypt.  It uses LWP::UserAgent to get a VOMS credential from a compatable server. 

  voms-proxy-init VOMSURI \
                  [ -cert /path/to/cert.pem ] \
                  [ -key /path/to/cert's/key.pem ] \
                  [ -out /path/to/save/proxy ] \
                  [ -CApath /path/to/CA/directory (to verify VOMS server against) ] \.
                  [ -lifetime N (hours, default 12 hours) ] \
                  [ -pl N  ] \
                  [ -(old|new|rfc|limited)] \
                  [ -verbose ( shows warnings and thinking )] \
                  [ -debug ( shows encrypted/decrypted wire traffic ) ]

=head1 DESCRIPTION

Creates a 512 bit proxy certificate which includs a VOMS attribute certificate.

VOMSURI is either
vomss://voms.server.fqdn:port/VO/Subgroup/.../Role=role/Capability=capability
https://voms.server.fqdn:port/VO/Subgroup/.../Role=role/Capability=capability. 
  where Subgroup, Role and Capability are optional.

use the vomss:// style uri to contact gLite VOMS vomsd servers 
and the https:// style uri to contact RESTful servers (https GET protocol)

=head1 SEE ALSO

This script was originally designed for SHEBANGS, a JISC funded project at The University of Manchester.
http://www.rcs.manchester.ac.uk/projects/shebangs/

Modifications (gLite VOMS support) made for JISC funded SARoNGS project.
http://www.rcs.manchester.ac.uk/projects/sarongs/

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
