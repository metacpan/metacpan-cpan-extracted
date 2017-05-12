#!/usr/local/bin/perl -w                                                        
use strict;
use warnings;

use Test::More tests => 1;

use UMLS::Interface;
use File::Spec;
use File::Path;

if(!(-d "t")) {   
    print STDERR "Error - program must be run from UMLS::Similarity\n";
    print STDERR "directory as : perl t/findCuiDepth.t \n";
    exit;  
}

#  initialize option hash
my %option_hash = ();

#  set the option hash
$option_hash{"realtime"} = 1;
$option_hash{"t"} = 1;
                    
#  connect to the UMLS-Interface
my $umls = UMLS::Interface->new(\%option_hash);
ok($umls);

#  get the version of umls that is being used
my $version = $umls->version();

#  set the key directory (create it if it doesn't exist)
my $keydir = File::Spec->catfile('t','key', $version);
if(! (-e $keydir) ) {
    File::Path->make_path($keydir);
}

my $perl     = $^X;
my $util_prg = File::Spec->catfile('utils', 'findCuiDepth.pl');

my ($keyfile, $config, $infile, $output);

