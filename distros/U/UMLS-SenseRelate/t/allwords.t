#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/lch.t'

#  This scripts tests some of the options available in Interface.pm


BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

use UMLS::Interface;
use UMLS::Similarity;
use UMLS::SenseRelate::AllWords;
$loaded = 1;
print "ok 1\n";

use strict;
use warnings;

#  initialize option hash and umls
my %option_hash = ();
my %params      = ();
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
$params{"measure"} = "path";
$params{"candidates"} = 1;
$senserelate = UMLS::SenseRelate::AllWords->new($umls, $meas);
if(!$senserelate) { print "not ok 4\n"; }
else              { print "ok 4\n";     }

#  set the context array
my @context = ();
push @context, "<head id=\"d001.s001.t001\" candidates=\"C1280500,C2348382\">effect</head>";
push @context, "of";
push @context, "the";
push @context, "duration";
push @context, "of";
push @context, "prefeeding";
 push @context, "on";
push @context, "<head id=\"d001.s001.t008\" candidates=\"C0001128,C0002520\">amino acid</head>";
push @context, "digestibility";
push @context, "of";
push @context, "<head id=\"d001.s001.t011\" candidates=\"C0043137,C0087114\">wheat</head>";
push @context, "distillers";

 #  check the assign senses option
my $arrayref = $senserelate->assignSenses(\@context);

if(!$arrayref) { print "not ok 5\n"; }
else           { print "ok 5\n"; }


