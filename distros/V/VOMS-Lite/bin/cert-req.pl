#!/usr/bin/perl

use VOMS::Lite::PEMHelper qw(readCert readAC readPrivateKey writeCert writeKey);
use VOMS::Lite::ASN1Helper qw(ASN1Wrap ASN1Unwrap DecToHex Hex ASN1BitStr);
use VOMS::Lite::REQ;

my $name=$0;
my $lname=length($name);
$name =~ s#.*/##g;
my $usage = "Usage: $name [ -cert /path/to/cert.pem ]\n".
" " x ($lname+6). "[ -key /path/to/request signers/key.pem ]\n".
" " x ($lname+6). "[ -out /path/to/save/req ]\n".
" " x ($lname+6). "[ -keyout /path/to/save/key ]\n".
" " x ($lname+6). "[ -passout password-to-encrypt-output-key ]\n".
" " x ($lname+6). "[ -pass password-to-decrypt-cert-key ]\n".
" " x ($lname+6). "[ -bits N (any of {512|1024|2048|4096} default 1024) ]\n".
" " x ($lname+8). "[ -host dns.of.host.for.alt.name ]\n".
" " x ($lname). "The following will be processsed in the order they are encountered\n".
" " x ($lname+6). "[ -C countryName ]\n".
" " x ($lname+6). "[ -O Organisation ]\n".
" " x ($lname+6). "[ -OU OrganisationUnit ]\n".
" " x ($lname+6). "[ -L Location ]\n".
" " x ($lname+6). "[ -DC DomainComponent ]\n".
" " x ($lname+6). "[ -ST StateOrProvince ]\n".
" " x ($lname+6). "[ -UID UserID ]\n".
" " x ($lname+6). "[ -Email emailAddress ]\n".
" " x ($lname+6). "[ -CN CommonName ]\n";

my %Input;
my $outfile;
my $outkeyfile;
my $lifetime=8544;
my $passout;
my $pass;
my $Key;

while ($_=shift @ARGV) {
  if    ( /^--?cert$/ ) {
    my $Cert=shift @ARGV;
    die "$& requires an argument\n$usage" if ( ! defined $Cert );
    die "cannot open CA certificate file $Cert\n$usage" if ( ! -r $Cert );
    my @decodedCERTS=readCert($Cert);
    $Input{'Cert'}=$decodedCERTS[0];
  }
  elsif ( /^--?key$/ ) {
    $Key=shift @ARGV;
    die "$_ requires an argument\n$usage" if ( ! defined $Key );
    die "cannot open key file $Key\n$usage" if ( ! -r $Key );
  }
  elsif ( /^--?out$/ ) {
    $outfile=shift @ARGV;
    die "$_ requires an argument\n$usage" if ( ! defined $outfile );
  }
  elsif ( /^--?keyout$/ ) {
    $outkeyfile=shift @ARGV;
    die "$_ requires an argument\n$usage" if ( ! defined $outkeyfile );
  }
  elsif ( /^--?bits$/ ) {
    my $bits=shift @ARGV;
    die "$_ requires an argument\n$usage" if ( ! defined $bits );
    die "$_ requires a valus of 512, 1024, 2048 or 4096.\n$usage" if ( $bits !~ /^(512|1024|2048|4096)$/ );
    $Input{'Bits'}=$bits;
  }
  elsif ( /^--?host$/ ) {
    $host=shift @ARGV;
    die "$_ requires an argument" if ( ! defined $host );
  }
  elsif ( /^--?passout$/ ) {
    $passout=shift @ARGV;
    die "$_ requires an argument\n$usage" if ( ! defined $passout );
  }
  elsif ( /^--?pass$/ ) {
    $pass=shift @ARGV;
    die "$_ requires an argument\n$usage" if ( ! defined $pass );
  }
  elsif ( /^--?(C|O|OU|L|DC|ST|UID|Email|CN)$/ ) {
    my $value=shift @ARGV;
    die "$_ requires an argument\n$usage" if ( ! defined $value );
    push @DN,"$1=$value";
    if ( $1 eq "Email" ) { $email=$value; }
  }
  else { die "Unrecognised option \"$_\"\n$usage"; }
}

$lifetime *= 3600 * 24 * 356; # 1 year
if ( ! defined $outfile ) { die "Certificate output file not specified.\n$usage"; } 
if ( ! defined $outkeyfile && ! defined $Key) { die "Key output file not specified.\n$usage"; } 

if ( @DN == 0 && ! defined $Input{'Cert'} ) { die "No DN attributes specified.\n$usage"; } 
if ( @DN != 0 ) { $Input{'DN'}=\@DN; }

if ( defined $Key ) { $Input{'Key'}=readPrivateKey($Key,$pass); }
if ( defined $host ) { $Input{'subjectAltName'}=["dNSName=$host"]; }
elsif ( defined $email ) { $Input{'subjectAltName'}=["rfc822Name=$email"]; }



my %Output = %{ VOMS::Lite::REQ::Create(\%Input) };

if ( ! defined $Output{Req} || ! defined $Output{Key} ) {
  foreach ( @{ $Output{Errors} } ) { print "Error:   $_\n"; }
  die "Failed to create X509 Certificate";
}

foreach ( @{ $Output{Warnings} } ) { print "Warning: $_\n"; }

writeCert($outfile, $Output{'Req'}, "CERTIFICATE REQUEST"); ### Needs it's type changing
if ( ! defined $Key) {
  writeKey($outkeyfile, $Output{'Key'}, $passout);
}

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
