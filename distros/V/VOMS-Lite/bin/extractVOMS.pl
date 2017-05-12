#!/usr/bin/perl

use VOMS::Lite::PEMHelper qw(readCert writeAC);
use VOMS::Lite::CertKeyHelper qw(buildchain);
use VOMS::Lite::X509;

my $cert=undef;

while ($_=shift @ARGV) {
  if    ( /^(--?cert)$/ ) { 
    $cert=shift @ARGV; 
    die "$1 requires an argument" if ( ! defined $cert );
    die "cannot open certificate file $cert" if ( ! -r $cert );
  }
  elsif ( /^(--?out)$/ ) { 
    $out=shift @ARGV; 
    die "$1 requires an argument" if ( ! defined $out );
  }
  else { die "Unrecognised option \"$_\"\nUsage: $0 [ -cert /path/to/cert.pem ] [ -out /path/to/save/AC.pem ]"; }
}

if ( ! defined $cert ) {
  if ( defined $ENV{X509_USER_PROXY} && $ENV{X509_USER_PROXY} =~ /(.*)/ ) { $cert=$1; }
  else { $cert="/tmp/x509up_u$<" };
}

if ( ! defined $out ) {
  if ( defined $ENV{VOMS_USER_AC} && $ENV{VOMS_USER_AC} =~ /(.*)/ ) { $out=$1; }
  else { $out="/tmp/vomsAC_u$<" };
}

my @cert=readCert($cert);
my %Chain = %{ buildchain( { suppliedcerts => \@cert } ) };

my $got=0;
for ( my $i=0;$i<@{ $Chain{Certs} };$i++) {
  print "Checking ".${ $Chain{DistinguishedNames} }[$i]." for VOMS Attribute Extension ... ";
  my $AC=${VOMS::Lite::X509::Examine($cert[$i],{'Extension:1.3.6.1.4.1.8005.100.100.5' => "" })}{'Extension:1.3.6.1.4.1.8005.100.100.5'};

  if ( $AC eq "" ) { print "Nope!\n";} 
  elsif ( $got == 0 )  { 
    print "Found!\nWriting it out to $out\n";
    if ( $AC ne "" ) { writeAC($out,$AC); }
    $got++;
  }
  else {
    print "Found!\nNOT Writing it out to file\n";
  }
}

__END__

=head1 NAME

  extractVOMS.pl

=head1 SYNOPSIS

  extractVOMS.pl [ -cert /path/to/cert.pem ] [ -out /path/to/save/AC.pem ]

=head1 DESCRIPTION

Extracts the VOMS AC from a GSI Proxy or X509 certificate and saves it in /tmp/vomsAC_u<UID>.
Use -cert to specify the proxy certificate or x509 certificate from which to extract the AC.
Use -out to specift the filename to save the PEM encoded Attribute Certificate.

=head1 SEE ALSO

This module was originally designed for SHEBANGS, a JISC funded project at The University of Manchester.
http://www.mc.manchester.ac.uk/projects/shebangs/
 now http://www.rcs.manchester.ac.uk/projects/shebangs/

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

