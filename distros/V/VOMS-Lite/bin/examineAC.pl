#!/usr/bin/perl

use VOMS::Lite::PEMHelper qw(readAC);
use VOMS::Lite::ASN1Helper qw(Hex);
use VOMS::Lite::AC;
use Pod::Simple::Text;
use VOMS::Lite::PEMHelper qw(encodeAC);

my $ac=undef;
my %input=(End=>"",FQANs=>"",HolderIssuerDN=>"",Start=>"",IssuerDN=>"",Verify=>"");
my $name=$0;
my ($basename)=$name =~ m|([^/]*)$|;
my $noout=0;

while ($_=shift @ARGV) {
  if ( /^(--?ac)$/ ) { 
    $ac=shift @ARGV; 
    die "$1 requires an argument" if ( ! defined $ac );
    die "cannot open ac file $ac" if ( ! -r "$ac" );
  }
  elsif ( /--?noout$/ ) {
    $noout=1;
  }
  elsif ( /^(--?help)$/ ) { Pod::Simple::Text->filter($name); exit 0; }
  else { die "Unrecognised option: try \"$basename -help\""; }
}

if ( ! defined $ac ) {
  if ( defined $ENV{VOMS_USER_AC} && $ENV{VOMS_USER_AC} =~ /(.*)/ ) { $ac=$1; }
  else { $ac="/tmp/vomsAC_u$<" };
}

my @ac=readAC($ac);

my @AC=VOMS::Lite::AC::Examine($ac[0],{End=>"",FQANs=>"",HolderIssuerDN=>"",Start=>"",IssuerDN=>"",Verify=>""} );

my $time=time();

foreach (@AC) {
  my %hash=%{ $_ };
  if ( $hash{Verify} ) { 
    print "The AC validates against the ".(($hash{InternalVOMSCert} eq "Attached" )?"attached":"locally stored")." valid certificate $hash{IssuerDN}\n"; 
  }
  foreach (keys %hash ) {
    if (defined $hash{$_} ) { 
      
      if ( $_ ne "Verify" ) {print "$_, ".((ref($hash{$_}) eq "ARRAY")?join(', ',@{ $hash{$_} }):$hash{$_})."\n"; }
    }
  }

  if ( $time < $hash{'Start'} ) {
    my $tl=$hash{Start};
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
                                      : "0 seconds" );
    print "Valid in $timeleftstr\n";
  }

  if ( $time > $hash{'End'} ) {
    my $tl=$hash{End};
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
                                      : "0 seconds" );
    print "Expires in $timeleftstr\n";
  }
  print "\n";
}

print "".encodeAC(@ac)."\n" if ( $noout == 0 ); 

__END__

=head1 NAME

  examineAC.pl

=head1 SYNOPSIS

  examineAC.pl [ -ac /path/to/AC.pem ] \
               [ -noout ]

=head1 DESCRIPTION

Parses the Attribte Certificate in /tmp/vomsAC_u<UID>, printing information to the terminal.
This script will print 
  End time,         -> when the attribute will expire
  Start time,       -> when the attribute is valid from
  Holder Issuer DN, -> The certificate to which the AC belongs' Issuer DN
  Holder Serial,    -> The Serial Number of the Certificate to which the AC belongs.
  Issuer DN         -> The Issuer DN of the VOMS Attribute Certificate
  The Attribute Certificate.
Use 
  -ac /path/to/AC/pem, to provide the path the the Attribute certificate if not in /tmp/vomsAC_u<UID>
  -noout, to repress printing of the PEM encoded Attribute certificate

=head1 SEE ALSO

This script was originally designed for VOMS::Lite, as a tool for the UK NGS SARoNGS service.
NGS is funded by the UK Research Councils JISC and EPSRC

http://www.mc.manchester.ac.uk/projects/shebangs/
 now http://www.rcs.manchester.ac.uk/projects/shebangs/

Mailing list, shebangs@listserv.manchester.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

