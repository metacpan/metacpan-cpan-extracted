#!/usr/bin/perl

use VOMS::Lite qw(Issue);
use VOMS::Lite::PEMHelper qw(writeAC readCert);

my @certs=readCert("/home/zzcgumj/.globus/usercert.pem");
#my @certs=readCert("/tmp/x509up_u$<");

#my $ReqAttribs=( "/Dummy" );
my $ReqAttribs=( "/ngs.ac.uk" );

my $ref=VOMS::Lite::Issue( \@certs, $ReqAttribs );
my %hash=%$ref;

foreach my $hash (keys %hash) {
  if ( ref($hash{$hash}) eq "ARRAY" ) {
    my $arrayref=$hash{$hash};
    my @array=@$arrayref;
    my $tmp=$hash;
    foreach (@array) { printf "%-15s %s\n", "$tmp:","$_"; $tmp=""; }
  }
}

writeAC("/tmp/ac.pem",$$ref{AC});
