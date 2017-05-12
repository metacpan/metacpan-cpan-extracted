#!/usr/bin/perl

use VOMS::Lite::PEMHelper qw(readCert readPrivateKey writeCert writeKey);
use VOMS::Lite::ASN1Helper qw(ASN1Wrap ASN1Unwrap DecToHex Hex ASN1BitStr);
use VOMS::Lite::X509;

my $name=$0;
$name =~ s#.*/##g;
my $lname=length($name);
my $usage = "Usage: $name [ -cacert /path/to/cacert.pem ]\n".
" " x ($lname+8). "[ -cakey /path/to/cacert's/key.pem ]\n".
" " x ($lname+8). "[ -out /path/to/save/cert ]\n".
" " x ($lname+8). "[ -outkey /path/to/save/key ]\n".
" " x ($lname+8). "[ -passout password-to-encrypt-output-key ]\n".
" " x ($lname+8). "[ -capass password-to-decrypt-cakey ]\n".
" " x ($lname+8). "[ -lifetime N (hours, default 8544 hours (365 days)) ]\n".
" " x ($lname+8). "[ -serial N ]\n".
" " x ($lname+8). "[ -host dns.of.host.for.alt.name ]\n".
" " x ($lname+8). "[ -bits N (any of {512|1024|2048|4096} default 1024) ]\n".
" " x ($lname+8). "[ -CA  ]\n".
"       ". "The following will be processsed in the order they are encountered\n".
" " x ($lname+8). "[ -C countryName ]\n".
" " x ($lname+8). "[ -O Organisation ]\n".
" " x ($lname+8). "[ -OU OrganisationUnit ]\n".
" " x ($lname+8). "[ -L Location ]\n".
" " x ($lname+8). "[ -DC DomainComponent ]\n".
" " x ($lname+8). "[ -ST StateOrProvince ] (Not recommended)\n".
" " x ($lname+8). "[ -UID UserID ] (Not recommended)\n".
" " x ($lname+8). "[ -Email emailAddress ]\n".
" " x ($lname+8). "[ -CN CommonName ]\n";

my %Input;
my $outfile;
my $outkeyfile;
my $CA;
my $lifetime=8544;
my $passout;
my $capass;
my $CAKey;
my $host;
my $email;

while ($_=shift @ARGV) {
  if    ( /^--?cacert$/ ) {
    my $CACert=shift @ARGV;
    die "$& requires an argument" if ( ! defined $CACert );
    die "cannot open CA certificate file $CACert" if ( ! -r $CACert );
    my @decodedCERTS=readCert($CACert);
    $Input{'CACert'}=$decodedCERTS[0];
  }
  elsif ( /^--?cakey$/ ) {
    $CAKey=shift @ARGV;
    die "$_ requires an argument" if ( ! defined $CAKey );
    die "cannot open CA key file $CAKey" if ( ! -r $CAKey );
  }
  elsif ( /^--?out$/ ) {
    $outfile=shift @ARGV;
    die "$_ requires an argument" if ( ! defined $outfile );
  }
  elsif ( /^--?outkey$/ ) {
    $outkeyfile=shift @ARGV;
    die "$_ requires an argument" if ( ! defined $outkeyfile );
  }
  elsif ( /^--?lifetime$/ ) {
    $lifetime=shift @ARGV;
    die "$_ requires an argument" if ( ! defined $lifetime );
    die "$_ requires a positive numeric integer argument." if ( $lifetime !~ /^[0-9]+$/ );
  }
  elsif ( /^--?serial$/ ) {
    my $serial=shift @ARGV;
    die "$_ requires an argument" if ( ! defined $serial );
    die "$_ requires a positive numeric integer argument." if ( $serial !~ /^[0-9]+$/ );
    $Input{'Serial'}=$serial;
  }
  elsif ( /^--?bits$/ ) {
    my $bits=shift @ARGV;
    die "$_ requires an argument" if ( ! defined $bits );
    die "$_ requires a valus of 512, 1024, 2048 or 4096." if ( $bits !~ /^(512|1024|2048|4096)$/ );
    $Input{'Bits'}=$bits;
  }
  elsif ( /^--?host$/ ) {
    $host=shift @ARGV;
    die "$_ requires an argument" if ( ! defined $host );
  }
  elsif ( /^--?passout$/ ) {
    $passout=shift @ARGV;
    die "$_ requires an argument" if ( ! defined $passout );
  }
  elsif ( /^--?capass$/ ) {
    $capass=shift @ARGV;
    die "$_ requires an argument" if ( ! defined $capass );
  }
  elsif ( /^--?CA$/ ) {
    $CA="True";
    $Input{'CA'}=$CA;
  }
  elsif ( /^--?EEC$/ ) {
    $CA="False";
    $Input{'CA'}=$CA;
  }
  elsif ( /^--?(C|O|OU|L|DC|ST|UID|Email|CN)$/ ) {
    my $value=shift @ARGV;
    die "$_ requires an argument" if ( ! defined $value );
    push @DN,"$1=$value";
    if ( $1 eq "Email" ) { $email=$value; }
  }
  else { die "Unrecognised option \"$_\"\n$usage"; }
}

$lifetime *= 3600; # Seconde -> hours
if ( ! defined $outfile ) { die "Certificate output file not specified."; } 
if ( ! defined $outkeyfile ) { die "Key output file not specified."; } 
if ( ! defined $Input{'Serial'} ) { die "Serial number not specified."; } 
if ( @DN == 0 ) { die "No DN attributes specified."; } 

if ( defined $CAKey ) { $Input{'CAKey'}=readPrivateKey($CAKey,$capass); }
$Input{'Lifetime'}=$lifetime;
$Input{'DN'}=\@DN;
if ( defined $host ) { $Input{'subjectAltName'}=["dNSName=$host"]; }
elsif ( defined $email ) { $Input{'subjectAltName'}=["rfc822Name=$email"]; }

my %Output = %{ VOMS::Lite::X509::Create(\%Input) };

if ( ! defined $Output{Cert} || ! defined $Output{Key} ) {
  foreach ( @{ $Output{Errors} } ) { print "Error:   $_\n"; }
  die "Failed to create X509 Certificate";
}

foreach ( @{ $Output{Warnings} } ) { print "Warning: $_\n"; }

writeCert($outfile, $Output{'Cert'});
writeKey($outkeyfile, $Output{'Key'}, $passout);

__END__

=head1 NAME

  cert-init.pl

=head1 SYNOPSIS

  cert-init.pl [ -cacert /path/to/cacert.pem ]
               [ -cakey /path/to/cacert's/key.pem ]
               [ -out /path/to/save/cert ]
               [ -outkey /path/to/save/key ]
               [ -passout password-to-encrypt-output-key ]
               [ -capass password-to-decrypt-cakey ]
               [ -lifetime N (hours, default 8544 hours (365 days)) ]
               [ -serial N ]
               [ -host dns.of.host.for.alt.name ]
               [ -bits N (any of {512|1024|2048|4096} default 1024) ]
               [ -CA  ]
         The following will be processsed in the order they are encountered
               [ -C countryName ]
               [ -O Organisation ]
               [ -OU OrganisationUnit ]
               [ -L Location ]
               [ -DC DomainComponent ]
               [ -ST StateOrProvince ] (Not recommended)
               [ -UID UserID ] (Not recommended)
               [ -Email emailAddress ]
               [ -CN CommonName ]

=head1 DESCRIPTION

Creates an X.509 certificate and key.

=head1 SEE ALSO

This script was originally designed for SHEBANGS, a JISC funded project at The University of Manchester.
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
