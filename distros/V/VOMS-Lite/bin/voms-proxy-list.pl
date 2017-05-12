#!/usr/bin/perl

use VOMS::Lite::VOMS;
use VOMS::Lite::PEMHelper qw(readCert readAC readPrivateKey writeCertKey decodeCert);
use VOMS::Lite::ASN1Helper qw(ASN1Wrap ASN1Unwrap DecToHex Hex ASN1BitStr);
use VOMS::Lite::PROXY;

my $name=$0;
my $lname=length($name);
$name =~ s#.*/##g;
my $usage = "Usage: $name vomss://voms.server:port/VO [ -cert /path/to/cert.pem ]\n".
" " x ($lname+8). "[ -key /path/to/cert's/key.pem ]\n".
" " x ($lname+8). "[ -CApath /path/to/CA/directory (to verify VOMS server against) ]\n".
" " x ($lname+8). "[ -verbose  ]\n";

my %Input;
my $HolderCert="$ENV{HOME}/.globus/usercert.pem";
my $HolderKey="$ENV{HOME}/.globus/userkey.pem";
my $CAPath="/etc/grid-security/certificates";
if ( defined $ENV{"X509_CERT_PATH"} && $ENV{"X509_CERT_PATH"} =~ /(.*)/ ) { $CAPath=$1; };
my $outfile="/tmp/x509up_u$<";
if ( defined $ENV{"X509_USER_PROXY"} && $ENV{"X509_USER_PROXY"} =~ /(.*)/ ) { $outfile=$1; };
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
  elsif ( /^vomss:\/\/.*$/ ) {
    push @VOMSURI,$&;
  }
  elsif ( /^https:\/\/.*$/ ) {
    push @VOMSURI,$&;
  }
  elsif ( /^--?v(?:erbose)?$/ )  { $verbose=1; }
  elsif ( /^--?debug$/ ) { $VOMS::Lite::VOMS::DEBUG="yes"; $verbose=1; }
  else { die "Unrecognised option \"$_\"\n$usage"; }
}

# Then make load a cert
my @decodedCERTS=readCert($HolderCert);
$Input{'Cert'}=$decodedCERTS[0];
$Input{'Key'}=readPrivateKey($HolderKey);

$ENV{HTTPS_CA_DIR}    = $CAPath;
$ENV{HTTPS_CERT_FILE} = $HolderCert;
$ENV{HTTPS_KEY_FILE}  = $HolderKey;

my %URI;
foreach (@VOMSURI) {
  if ( m|(vomss://[^:]+:[^/]+/[^/]+)| ) {
    $URI{$1}="";
  } elsif ( m|https://[^:]+(?::[0-9]{1,5})?/.+| ) {
    die "https scheme currently unsupported."
  }
  else {
    die "Baddly formatted VO string \"$_\"\n$usage";
  }
}

my @FQANs;
foreach my $URI (keys %URI) {
  if ( $URI =~ m|vomss://([^:]+):([^/]+)/([^/]+)?| ) {
    print "Contacting $URI for using $HolderCert\n" if ($verbose);
    my $ref = VOMS::Lite::VOMS::List( { Server => "$1", 
                                          Port => $2,
                                            VO => $3, 
                                        CAdirs => $CAPath,
                                          Cert => $Input{'Cert'}, 
                                           Key => $Input{'Key'} } );

    if (@{ ${ $ref }{Errors} } )   { print "Errors:\n  ".(join "\n  ", @{ ${ $ref }{Errors} }).".\n"; die "Failed to list ".$URI; }
    if (@{ ${ $ref }{Warnings} } and $verbose==1) { print "Warnings for $1:$2\n  ".(join "\n  ", @{ ${ $ref }{Warnings} }).".\n"; }

    foreach (@{ ${ $ref }{FQANs} } ) { push @FQANs,$_; }
  }
}

print join("\n",@FQANs)."\n";
exit;

__END__

=head1 NAME

  voms-proxy-list.pl

=head1 SYNOPSIS

  An extension to the voms-proxy-init.pl scrypt. 

  voms-proxy-list VOMSURI \
                  [ -cert /path/to/cert.pem ] \
                  [ -key /path/to/cert's/key.pem ] \
                  [ -CApath /path/to/CA/directory (to verify VOMS server against) ] \.
                  [ -verbose ( shows warnings and thinking )] \
                  [ -debug ( shows encrypted/decrypted wire traffic ) ]

=head1 DESCRIPTION

Creates a 512 bit proxy certificate which includs a VOMS attribute certificate.

VOMSURI is of the format
vomss://voms.server.fqdn:port/VO/Subgroup/.../Role=role/Capability=capability
  where Subgroup, Role and Capability are optional.

use the vomss:// style uri to contact gLite VOMS vomsd servers 

=head1 SEE ALSO

This script was originally designed for SHEBANGS, a JISC funded project at The University of Manchester.
http://www.rcs.manchester.ac.uk/projects/shebangs/

Modifications (gLite VOMS support) made for JISC funded SARoNGS project.
http://www.rcs.manchester.ac.uk/projects/sarongs/

Further Modifications for the UK NGS project SARoNGS service.

Mailing list, shebangs@listserv.manchester.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 2011 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
