#!/usr/bin/perl

use VOMS::Lite::PEMHelper;
use VOMS::Lite::CertKeyHelper qw(buildchain);

my $cert;
my @CAdirs=(); 
my @CAfiles=();
my $quiet=0;
my $summary=0;

while ($_=shift @ARGV) {
  if    ( /^(--?cert)$/ ) { 
    $cert=shift @ARGV; 
    die "$1 requires an argument" if ( ! defined $cert );
    die "cannot open certificate file $cert" if ( ! -r $cert );
  }
  elsif ( /^(--?(?:ca|CA)(?:path|dir))$/ ) { 
    my $dir=shift @ARGV;
    die "$1 requires an argument" if ( ! defined $dir );
    die "$dir is not a directory" if ( ! -d $dir );
    push @CAdirs, $dir; 
  }
  elsif ( /^--?(?:ca|CA)file$/ ) { 
    my $file=shift @ARGV;
    die "$1 requires an argument" if ( ! defined $file );
    die "cannot open $file" if ( ! -r $file );
    push @CAfiles, $file;
  }
  elsif ( /^--?q(?:uiet)?$/ ) { $quiet=1; }
  elsif ( /^--?s(?:ummary)?$/ ) { $summary=1; }
  else { die "Unrecognised option \"$_\"\nUsage: $0 [-q] [-s] -cert <path to cert.pem> [ -cadir /path/to/CA/dir ] [ -cafile /path/to/a/CA.pem ]"; }
}

die "Usage: $0 [-q] [-s] -cert <path to cert.pem> [ -cadir /path/to/CA/dir ] [ -cafile /path/to/a/CA.pem ]" if ( ! defined $cert );
my @certs=VOMS::Lite::PEMHelper::readCert($cert);

my @CAcerts=();
foreach (@CAfiles) { print "$_\n"; push @CAcerts, VOMS::Lite::PEMHelper::readCert($_); }

my %Chain = %{ buildchain( { trustedCAdirs => \@CAdirs, 
                             suppliedcerts => \@certs, 
                             trustedCAs    => \@CAcerts } ) };

my @returnedCerts = @{ $Chain{Certs} }; 
my @IHash         = @{ $Chain{IssuerHashes} };
my @Hash          = @{ $Chain{SubjectHashes} };
my @SKID          = @{ $Chain{SubjectKeyIdentifiers} };
my @AKID          = @{ $Chain{AuthorityKeyIdentifiersSKIDs} };
my @DNs           = @{ $Chain{DistinguishedNames} };
my @IDNs          = @{ $Chain{IssuerDistinguishedNames} };
my @Trust         = @{ $Chain{TrustedCA} };
my $self          =    $Chain{SelfSignedInChain};
my @GSI           = @{ $Chain{GSIType} };
my $EECDN         =    $Chain{EndEntityDN};
my $EECIDN        =    $Chain{EndEntityIssuerDN};
my $EEC           =    $Chain{EndEntityCert};
my @LifeTime      = @{ $Chain{Lifetimes} };
my @Errors        = @{ $Chain{Errors} };
my $Err           = 0;
my $Trust         = 0;
my $comltstr;
my $comlifetime   = $LifeTime[0];

while ( $#returnedCerts >= 0 ) {
  my $timeleft = shift @LifeTime;
  my $tl       = $timeleft;
  my $y = int( $tl / 31556736 ); $tl %= 31556736;
  my $d = int( $tl / 86400 );    $tl %= 86400;
  my $h = int( $tl / 3600 );     $tl %= 3600;
  my $m = int( $tl / 60 );       $tl %= 60;
  my $s = $tl;
  my $timeleftstr = (($timeleft>0) ? (( ($y>0) ?                         "$y years, "   : "").
                                      ( ($d>0||$y>0) ?                   "$d days, "    : "").
                                      ( ($h>0||$d>0||$y>0) ?             "$h hours, "   : "").
                                      ( ($m>0||$h>0||$d>0||$y>0) ?       "$m minutes, " : "").
                                      ( ($s>0||$m>0||$h>0||$d>0||$y>0) ? "$s seconds, " : ""))
                                    : "0" );
  if ( $timeleft <= $comlifetime ) { $comlifetime = $timeleft; $comltstr=$timeleftstr; }
  $Trust=1 if ($Trust[-1]);
  my @certErrors=@{ shift @Errors };
  my $errstr="";
  if ( $#certErrors >=0 ) { $Err=1; foreach (@certErrors) { $errstr .= "ERROR:      $_\n"; } }

  my $status = "DN             ".(shift @DNs)."\n".
               "Hash           ".(shift @Hash)."\n".
               "Issuer DN      ".(shift @IDNs)."\n".
               "Issuer Hash    ".(shift @IHash)."\n".
               "GSI Status     ".(shift @GSI)."\n".
               "Time remaining $timeleftstr\n".
               "Trusted        ".(((shift @Trust) == 1)?"yes\n":"no\n").
               "$errstr".
               VOMS::Lite::PEMHelper::encodeCert(shift @returnedCerts) . "\n";

  print $status if ( ! $summary && ! $quiet );
}

if ( ! $quiet ) {
  print "Over all remaining time: $comltstr\n";
  print "Chain is".(( $self == 1 )?"":" NOT")." complete.\n";
  print "Chain ".(( $Trust == 1 )?"contains":"does NOT contain")." a local trust anchor.\n";
  print "There were errors in the validation.\n" if ( $Err == 1 );
}

my $ret=0;
$ret+=1 if ( $Trust == 0 );
$ret+=2 if ( $self == 0 );
$ret+=4 if ( $Err == 1 );
exit($ret);

__END__

=head1 NAME

  verifycert.pl

=head1 SYNOPSIS

  A simple script to verify X509 and GSI certificates. 

  verifycert.pl [-q] [-s] -cert <path to cert.pem> [ -cadir /path/to/CA/dir ] [ -cafile /path/to/a/CA.pem ]

=head1 DESCRIPTION

  Need I say more?

=head1 SEE ALSO

VOMS::Lite

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


