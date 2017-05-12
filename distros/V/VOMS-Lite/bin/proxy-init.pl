#!/usr/bin/perl

use VOMS::Lite::PEMHelper qw(readCert readAC readPrivateKey writeCertKey);
use VOMS::Lite::ASN1Helper qw(ASN1Wrap ASN1Unwrap DecToHex Hex ASN1BitStr);
use VOMS::Lite::PROXY;
use VOMS::Lite::Audit;

my $name=$0;
my $lname=length($name);
$name =~ s#.*/##g;
my $usage = "Usage: $name [ -cert /path/to/cert.pem ]\n".
" " x ($lname+8). "[ -key /path/to/cert's/key.pem ]\n".
" " x ($lname+8). "[ -out /path/to/save/proxy ]\n".
" " x ($lname+8). "[ -vomsAC /path/to/VOMS/AC ]\n".
" " x ($lname+8). "[ -audit 'http://proxyaudit.endpoint' ]\n".
" " x ($lname+8). "[ -lifetime N (hours, default 12 hours) ]\n".
" " x ($lname+8). "[ -pl N  ]\n".
" " x ($lname+8). "[ -(old|new|rfc|limited)  ]\n".
" " x ($lname+8). "[ -limited  ]\n";

my %Input;
my $HolderCert="$ENV{HOME}/.globus/usercert.pem";
my $HolderKey="$ENV{HOME}/.globus/userkey.pem";
my $outfile="/tmp/x509up_u$<";
if ( defined $ENV{"X509_USER_PROXY"} && $ENV{"X509_USER_PROXY"} =~ /(.*)/ ) { $outfile=$1; };
my ($vomsattribfile,$pathlen,$lifetime,$audit);

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
  elsif ( /^--?vomsAC$/ ) {
    $vomsattribfile=shift @ARGV;
    die "$& requires an argument" if ( ! defined $vomsattribfile );
    die "cannot open certificate file $vomsattribfile" if ( ! -r $vomsattribfile );
  }
  elsif ( /^--?out$/ ) {
    $outfile=shift @ARGV;
    die "$& requires an argument" if ( ! defined $outfile );
  }
  elsif ( /^--?audit$/ ) {
    $audit=shift @ARGV;
    die "$& requires an argument" if ( ! defined $audit );
  }
  elsif ( /^--?limited$/ )      { $Input{'Type'}="Limited"; }
  elsif ( /^--?(new|gt3)$/ )    { $Input{'Type'}="Pre-RFC"; }
  elsif ( /^--?rfc$/ )          { $Input{'Type'}="RFC"; }
  elsif ( /^--?(old|legacy)$/ ) { $Input{'Type'}="Legacy"; }
  elsif ( /^--?(pl|pathlength)$/ ) {
    $pathlen=shift @ARGV;
    die "$& requires an argument" if ( ! defined $pathlen );
    die "Bad Pathlength argument, $& requires a positive integer" if ( $pathlen =~ /^[0-9]+$/ );
  }
  elsif ( /^--?lifetime$/ ) {
    $lifetime=shift @ARGV;
    die "$& requires an argument" if ( ! defined $lifetime );
    die "$& requires a positive numeric integer argument." if ( $lifetime =~ /^[0-9]+$/ );
    $lifetime*=3600;
  }
  else { die "Unrecognised option \"$_\"\n$usage"; }
}

my @decodedCERTS=readCert($HolderCert);
$Input{'Cert'}=$decodedCERTS[0];
$Input{'Key'}=readPrivateKey($HolderKey);
$Input{'Lifetime'}=$lifetime;
$Input{'PathLength'}=$pathlen;

if ( defined $vomsattribfile ) { $Input{'AC'}=readAC($vomsattribfile); }

if ( defined $audit ) { $Input{'Ext'} = [ VOMS::Lite::Audit::Create("$audit") ]; }

my %Output = %{ VOMS::Lite::PROXY::Create(\%Input) };

if ( ! defined $Output{ProxyCert} || ! defined $Output{ProxyKey} ) {
  foreach ( @{ $Output{Errors} } ) { print "Error:   $_\n"; }
  die "Failed to create proxy";
}

foreach ( @{ $Output{Warnings} } ) { print "Warning: $_\n"; }

writeCertKey($outfile, $Output{'ProxyCert'}, $Output{'ProxyKey'}, @decodedCERTS);

__END__

=head1 NAME

  proxy-init.pl

=head1 SYNOPSIS

  proxy-init [ -cert /path/to/cert.pem ] \
             [ -key /path/to/cert's/key.pem ] \
             [ -out /path/to/save/proxy ] \
             [ -vomsAC /path/to/VOMS/AC ] \.
             [ -lifetime N (hours, default 12 hours) ] \
             [ -pl N  ] \
             [ -(old|new|rfc|limited)]

=head1 DESCRIPTION

Creates a 512 bit proxy certificate optionally including a VOMS attribute certificate.

=head1 SEE ALSO

This module was originally designed for SHEBANGS, a JISC funded project at The University of
 Manchester.
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
