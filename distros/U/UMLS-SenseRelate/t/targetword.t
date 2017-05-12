#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/lch.t'

#  This scripts tests some of the options available in Interface.pm


BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

use UMLS::Interface;
use UMLS::Similarity;
use UMLS::SenseRelate::TargetWord;
$loaded = 1;
print "ok 1\n";

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
if(!$umls) { print "not ok 2\n"; }
else       { print "ok 2\n";     }


#  set measure
use UMLS::Similarity::path;
$meas = UMLS::Similarity::path->new($umls);
if(!$meas) { print "not ok 3\n"; }
else       { print "ok 3\n";     }


#  set senserelate
$senserelate = UMLS::SenseRelate::TargetWord->new($umls, $meas);
if(!$senserelate) { print "not ok 4\n"; }
else          { print "ok 4\n";     }

#  check the assign senses option
my $tw = "adjustment";
my $instance = "Fifty-three percent of the subjects reported below average marital <head>adjustment</head>.";

my ($hashref) = $senserelate->assignSense($tw, $instance, undef);

if(!$hashref) { print "not ok 5\n"; }
else          { print "ok 5\n"; }


