#!/usr/bin/perl

use VOMS::Lite::PEMHelper qw(writeCertKey);
use VOMS::Lite::MyProxy;
require Term::ReadKey;

my $name=$0;
my $lname=length($name);
$name =~ s#.*/##g;
my $usage = "Usage: $name username@myproxy.server[:port]\n".
" " x ($lname+8). "[ -out /path/to/save/proxy ]\n".
" " x ($lname+8). "[ -lifetime N (hours, default 12 hours) ]\n".

my %Input;
my $outfile="/tmp/x509up_u$<";
if ( defined $ENV{"X509_USER_PROXY"} && $ENV{"X509_USER_PROXY"} =~ /(.*)/ ) { $outfile=$1; };
my ($lifetime);

while ($_=shift @ARGV) {
  if ( /^--?lifetime$/ ) {
    $lifetime=shift @ARGV;
    die "$& requires an argument" if ( ! defined $lifetime );
    die "$& requires a positive numeric integer argument." if ( $lifetime =~ /^[0-9]+$/ );
    $lifetime*=3600;
    $Input{"Lifetime"}=$lifetime;
  }
  elsif ( /^([\/a-zA-Z0-9_ =.-]+)@([a-zA-Z0-9_][a-zA-Z0-9_.-]+[a-zA-Z0-9_])(?::([0-9]{1,5}))?$/ ) {
    $Input{"Username"}=$1;
    $Input{"Server"}=$2;
    $Input{"Port"}=$3;
  }
  else { die "Unrecognised option \"$_\"\n$usage"; }
}

# Prompt for password
if ( ! defined $Input{"Password"} ) {
  print "Passphrase to protect the credential on the MyProxy Server: ";
  my $dummy=Term::ReadKey::ReadMode('noecho');
  my $passwd = Term::ReadKey::ReadLine(),
  $dummy=Term::ReadKey::ReadMode('normal');
  chomp $passwd;
  $Input{"Password"}=$passwd;
  print "\n";
}

my %Output = %{ VOMS::Lite::MyProxy::Get(\%Input) };

my $cert= shift @{ $Output{CertChain} };

if ( ! defined $Output{CertChain} || ! defined $Output{Key} ) {
  foreach ( @{ $Output{Errors} } ) { print "Error:   $_\n"; }
  die "Failed to get a proxy";
}

foreach ( @{ $Output{Warnings} } ) { print "Warning: $_\n"; }

print "Retrieved\n";

writeCertKey($outfile, $cert, $Output{'Key'}, @{ $Output{CertChain} } );

__END__

=head1 NAME

  myproxy-get.pl

=head1 SYNOPSIS

  This needs writing, ignore the following...

  myproxy-get.pl username@myproxy.server[:port]
                 [ -out /path/to/save/proxy ] \
                 [ -lifetime N (hours, default 12 hours) ]

=head1 DESCRIPTION

Retrieves a proxy certificate from a MyProxy Server.

=head1 SEE ALSO

This program was originally designed for SHEBANGS, a JISC funded project at The Universities of
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
