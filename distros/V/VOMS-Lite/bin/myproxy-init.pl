#!/usr/bin/perl

use VOMS::Lite::PEMHelper qw(readCert readAC readPrivateKey);
use VOMS::Lite::MyProxy;
require Term::ReadKey;
use strict;

my $name=$0;
my $lname=length($name);
$name =~ s#.*/##g;
my $usage = "Usage: $name [username@]myproxy.server[:port]\n".
" " x ($lname+8). "[ -cert /path/to/cert.pem ]\n".
" " x ($lname+8). "[ -key /path/to/cert's/key.pem ]\n".
" " x ($lname+8). "[ -vomsAC /path/to/VOMS/AC ]\n".
" " x ($lname+8). "[ -lifetime N (hours, default 24) ]\n".
" " x ($lname+8). "[ -releaselifetime N (hours, default 9) ]\n".
" " x ($lname+8). "[ -pl N  ]\n".
" " x ($lname+8). "[ -(old|new|rfc|limited)  ]\n";

my %Input;
my $HolderCert="$ENV{HOME}/.globus/usercert.pem";
my $HolderKey="$ENV{HOME}/.globus/userkey.pem";
my ($vomsattribfile,$pathlen,$lifetime,$releaselifetime,$outfile,$server,$port,$username);
if ( defined $ENV{"X509_USER_PROXY"} && $ENV{"X509_USER_PROXY"} =~ /(.*)/ ) { $outfile=$1; };

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
  elsif ( /^--?limited$/ )      { $Input{'Type'}="Limited"; }
  elsif ( /^--?(new|gt3)$/ )    { $Input{'Type'}="Pre-RFC"; }
  elsif ( /^--?rfc$/ )          { $Input{'Type'}="RFC"; }
  elsif ( /^--?(old|legacy)$/ ) { $Input{'Type'}="Legacy"; }
  elsif ( /^--?(pl|pathlength)$/ ) {
    $pathlen=shift @ARGV;
    die "$& requires an argument" if ( ! defined $pathlen );
    die "Bad Pathlength argument, $& requires a positive integer" if ( $pathlen !~ /^[0-9]+$/ );
  }
  elsif ( /^(--?lifetime)$/ ) {
    $lifetime=shift @ARGV;
    die "$& requires an argument" if ( ! defined $lifetime );
    die "$& requires a positive numeric argument $&." if ( $lifetime !~ /^[0-9]*(?:\.[0-9]+)?$/ );
    $lifetime*=3600;
    $lifetime=int($lifetime);
  }
  elsif ( /^--?releaselifetime$/ ) {
    $releaselifetime=shift @ARGV;
    die "$& requires an argument" if ( ! defined $releaselifetime );
    die "$& requires a positive numeric argument." if ( $releaselifetime !~ /^[0-9]+(?:\.[0-9]+)?$/ );
    $releaselifetime*=3600;
    $releaselifetime=int($releaselifetime);
  }
  elsif ( /^([\/a-zA-Z0-9_ =.-]+)@([a-zA-Z0-9_-][a-zA-Z0-9_.-]+[a-zA-Z0-9_-])(?::([0-9]{1,5}))?$/ ) {
    $username=$1;
    $server=$2;
    $port=$3;
  }
  elsif ( /^([a-zA-Z0-9_][a-zA-Z0-9_.-]+[a-zA-Z0-9_])(?::([0-9]{1,5}))?$/ ) {
    $server=$1;
    $port=$2;
  }
  else { die "Unrecognised option \"$_\"\n$usage"; }
}

my @decodedCERTS=readCert($HolderCert);
$Input{'Server'}=$server;
$Input{'Username'}=$username;
$Input{'Port'}=$port;
$Input{'Cert'}=$decodedCERTS[0];
$Input{'Key'}=readPrivateKey($HolderKey);
$Input{'Lifetime'}=$lifetime;
$Input{'ReleaseLifetime'}=$releaselifetime;
$Input{'PathLength'}=$pathlen;
$Input{'Port'}=$port;
if ( defined $vomsattribfile ) { $Input{'AC'}=readAC($vomsattribfile); }

# Prompt for password
if ( ! defined $Input{"Password"} ) {
  print "Passphrase to protect the credential on the MyProxy Server: ";
  my $dummy=Term::ReadKey::ReadMode('noecho');
  my $passwd = Term::ReadKey::ReadLine(),
  $dummy=Term::ReadKey::ReadMode('normal');
  chomp $passwd;
  print "\nRetype passphrase to protect the credential on the MyProxy Server: ";
  my $dummy=Term::ReadKey::ReadMode('noecho');
  my $passwd2 = Term::ReadKey::ReadLine(),
  $dummy=Term::ReadKey::ReadMode('normal');
  chomp $passwd2;
  print "\n";
  if ( $passwd ne $passwd2 ) { die "Passphrases $passwd and $passwd2 did not match!";}
  $Input{"Password"}=$passwd;
}

my %Output = %{ VOMS::Lite::MyProxy::Init(\%Input) };

if ( defined $Output{Errors} ) {
  foreach ( @{ $Output{Errors} } ) { print "Error:   $_\n"; }
  die "Failed to create proxy";
}
foreach ( @{ $Output{Warnings} } ) { print "Warning: $_\n"; }

$lifetime =  int($Output{'Lifetime'}/3600) . "h " . int($Output{'Lifetime'} / 60) % 60 . "m " . $Output{'Lifetime'} % 60 . "s";
$releaselifetime = int($Output{'ReleaseLifetime'}/3600) . "h " . int($Output{'ReleaseLifetime'} / 60 ) % 60 . "m " . $Output{'ReleaseLifetime'} % 60 . "s";

print "Proxy Created $Output{Username}\@$Output{Server}".(($Output{Port} != 7512)?":$Output{Port}":"")."\nValid for $lifetime with a release policy lifetime restriction of $releaselifetime.\n";

__END__

=head1 NAME

  myproxy-init.pl

=head1 SYNOPSIS

  proxy-init [username@]fqdn.of.myproxy.server[:port] \
             [ -cert /path/to/cert.pem ] \
             [ -key /path/to/cert's/key.pem ] \
             [ -vomsAC /path/to/VOMS/AC ] \.
             [ -lifetime N (hours, default 24 hours) ] \
             [ -releaselifetime N (hours, default 9 hours) ] \
             [ -pl N  ] \
             [ -(old|new|rfc|limited)]

=head1 DESCRIPTION

Creates and delegates a 512 bit proxy certificate optionally including a VOMS attribute certificate to a MyProxy server.

=head1 SEE ALSO

This module was originally designed for SARoNGS, a JISC funded project at The Universities of
 Manchester and Oxford, and the Science and Technologies Research Council.

http://www.rcs.manchester.ac.uk/projects/sarongs/

Mailing list, SARONGS-DISCUSS@jiscmail.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
