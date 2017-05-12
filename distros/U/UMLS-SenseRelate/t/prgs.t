#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/lch.t'

#  This scripts tests the functionality of the utils/ programs

use strict;
use warnings;

use Test::More tests => 7;

BEGIN{ use_ok ('File::Spec') }

my $perl     = $^X;
my $util_prg = "";

my $output   = "";

#######################################################################################
#  check the umls-targetword-senserelate.pl program
#######################################################################################

$util_prg = File::Spec->catfile('utils', 'umls-targetword-senserelate.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/The input file or directory must be given on the command line.\s*Type umls-targetword-senserelate\.pl --help for help\.\s*Usage\: umls-targetword-senserelate\.pl \[OPTIONS\] INPUTFILE/);


#######################################################################################
#  check the umls-targetword-senserelate.pl program
#######################################################################################

$util_prg = File::Spec->catfile('utils', 'umls-senserelate-evaluation.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/The umls-targetword-senserelate log directory must be given on the command line.\s*Type umls-senserelate-evaluation\.pl --help for help\.\s*Usage\: umls-senserelate-evaluation\.pl \[OPTIONS\] LOG\_DIRECTORY/);

#######################################################################################
#  check the umls-allwords-senserelate.pl program
#######################################################################################

$util_prg = File::Spec->catfile('utils', 'umls-allwords-senserelate.pl');
ok(-e $util_prg);

#  check no command line inputs
$output = `$perl $util_prg 2>&1`;
like ($output, qr/The input file or directory must be given on the command line.\s*Type umls\-allwords-senserelate.pl \-\-help for help.\s*Usage\: umls\-allwords-senserelate.pl \[OPTIONS\] INPUTFILE/);
