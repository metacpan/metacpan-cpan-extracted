#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/lch.t'

#  This scripts tests some of the options available in Interface.pm


BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}

use UMLS::Interface;
$loaded = 1;
print "ok 1\n";

use UMLS::Similarity;
$loaded = 1;
print "ok 2\n";

use UMLS::SenseRelate::TargetWord;
$loaded = 1;
print "ok 3\n";

use strict;
use warnings;

#  initialize option hash and umls
my %option_hash = ();
my $umls        = "";
my $meas        = "";

#  check the realtime option
$option_hash{"realtime"} = 1;
$option_hash{"t"} = 1;

$umls = UMLS::Interface->new(\%option_hash);
if(!$umls) { print "not ok 4\n"; }
else       { print "ok 4\n";     }


#  check the forcerun option
%option_hash = ();
$option_hash{"forcerun"} = 1;
$option_hash{"t"} = 1;

$umls = UMLS::Interface->new(\%option_hash);
if(!$umls) { print "not ok 5\n"; }
else       { print "ok 5\n";     }

#  check a few of the measure options
use UMLS::Similarity::lch;
$meas = UMLS::Similarity::lch->new($umls);
if(!$meas) { print "not ok 6\n"; }
else       { print "ok 6\n";     }

use UMLS::Similarity::path;
$meas = UMLS::Similarity::path->new($umls);
if(!$meas) { print "not ok 7\n"; }
else       { print "ok 7\n";     }

use UMLS::Similarity::wup;
$meas = UMLS::Similarity::wup->new($umls);
if(!$meas) { print "not ok 8\n"; }
else       { print "ok 8\n";     }
