#!/usr/local/bin/perl 

use UMLS::Interface;
use UMLS::Similarity;
use UMLS::SenseRelate::TargetWord;

use strict;
use warnings;

#  initialize option hash and umls
my %option_hash = ();
my $umls        = "";
my $meas        = "";
my $senserelate = "";

#  set interface
$option_hash{"t"} = 1;
$option_hash{"realtime"} = 1;
$umls = UMLS::Interface->new(\%option_hash);

#  set measure
use UMLS::Similarity::path;
$meas = UMLS::Similarity::path->new($umls);

#  set senserelate
$senserelate = UMLS::SenseRelate::TargetWord->new($umls, $meas);

#  assign sense to target word
my $tw = "adjustment";
my $instance = "Fifty-three percent of the subjects reported below average marital <head>adjustment</head>.";

my ($hashref) = $senserelate->assignSense($tw, $instance, undef);

if(defined $hashref) {                                              
    print "Target word ($tw) was assigned the following sense(s):\n";
    foreach my $sense (sort keys %{$hashref}) {                     
	print "  $sense\n";
    } 
}
else {
    print "Target wrod ($tw) has no senses.\n";
}
