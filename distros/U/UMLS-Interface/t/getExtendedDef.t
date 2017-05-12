#!/usr/local/bin/perl -w   
# `make test'. After `make install' it should work as `perl access.t' 
##################### We start with some black magic to print on failure. 

use strict;
use warnings;

use Test::More tests => 17;

use UMLS::Interface;
use File::Spec;
use File::Path;

if(!(-d "t")) {   
    print STDERR "Error - program must be run from UMLS::Similarity\n";
    print STDERR "directory as : perl t/findExtendedDef.t \n";
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
my $util_prg = File::Spec->catfile('utils', 'getExtendedDef.pl');

my ($keyfile, $file, $output, $term, $config, $cui);

### Note : if a key for the version of UMLS is being run on 
###        exists we will test our run against the key 
###        otherwise the key will be created
#######################################################################################
#  check mth tests for term
#######################################################################################
$term    = "hand";
$file    = "getExtendedDef.mth.rb-rn.$term";
$keyfile = File::Spec->catfile($keydir, $file);
$config  = File::Spec->catfile('t', 'config', 'defconfig.mth.rb-rn');
$output = `$perl $util_prg --config $config $term 2>&1`;

if(-e $keyfile) {
    ok (open KEY, $keyfile) or diag "Could not open $keyfile: $!";
    my $key = "";
    while(<KEY>) { $key .= $_; } close KEY;
    cmp_ok($output, 'eq', $key);
}
else {
    ok(open KEY, ">$keyfile") || diag "Could not open $keyfile: $!";
    print KEY $output;
    close KEY; 
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}

#######################################################################################
#  check snomedct tests for term
#######################################################################################
$term    = "hand";
$file    = "getExtendedDef.snomedct.par-chd.$term";
$keyfile = File::Spec->catfile($keydir, $file);
$config  = File::Spec->catfile('t', 'config', 'defconfig.snomedct.par-chd');
$output = `$perl $util_prg --config $config $term 2>&1`;

if(-e $keyfile) {
    ok (open KEY, $keyfile) or diag "Could not open $keyfile: $!";
    my $key = "";
    while(<KEY>) { $key .= $_; } close KEY;
    cmp_ok($output, 'eq', $key);
}
else {
    ok(open KEY, ">$keyfile") || diag "Could not open $keyfile: $!";
    print KEY $output;
    close KEY;
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}

#######################################################################################
#  check msh tests for term
#######################################################################################
$term    = "hand";
$file    = "getExtendedDef.msh.par-chd.$term";
$keyfile = File::Spec->catfile($keydir, $file);
$config  = File::Spec->catfile('t', 'config', 'defconfig.msh.par-chd');
$output = `$perl $util_prg --config $config $term 2>&1`;

if(-e $keyfile) {
    ok (open KEY, $keyfile) or diag "Could not open $keyfile: $!";
    my $key = "";
    while(<KEY>) { $key .= $_; } close KEY;
    cmp_ok($output, 'eq', $key);
}
else {
    ok(open KEY, ">$keyfile") || diag "Could not open $keyfile: $!";
    print KEY $output;
    close KEY;
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}

#######################################################################################
#  check mth rb-rn tests for cui
#######################################################################################
$cui    = "C0018563";
$file    = "getExtendedDef.mth.rb-rn.$cui";
$keyfile = File::Spec->catfile($keydir, $file);
$config  = File::Spec->catfile('t', 'config', 'defconfig.mth.rb-rn');
$output = `$perl $util_prg --config $config $term 2>&1`;

if(-e $keyfile) {
    ok (open KEY, $keyfile) or diag "Could not open $keyfile: $!";
    my $key = "";
    while(<KEY>) { $key .= $_; } close KEY;
    cmp_ok($output, 'eq', $key);
}
else {
    ok(open KEY, ">$keyfile") || diag "Could not open $keyfile: $!";
    print KEY $output;
    close KEY; 
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}

#######################################################################################
#  check snomedct par-chd tests for cui
#######################################################################################
$cui    = "C0018563";
$file    = "getExtendedDef.snomedct.par-chd.$cui";
$keyfile = File::Spec->catfile($keydir, $file);
$config  = File::Spec->catfile('t', 'config', 'defconfig.snomedct.par-chd');
$output = `$perl $util_prg --config $config $cui 2>&1`;

if(-e $keyfile) {
    ok (open KEY, $keyfile) or diag "Could not open $keyfile: $!";
    my $key = "";
    while(<KEY>) { $key .= $_; } close KEY;
    cmp_ok($output, 'eq', $key);
}
else {
    ok(open KEY, ">$keyfile") || diag "Could not open $keyfile: $!";
    print KEY $output;
    close KEY;
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}
#######################################################################################
#  check snomedct par-chd-rb-rn tests  for cui
#######################################################################################
$cui    = "C1281583";
$file    = "getExtendedDef.snomedct.par-chd-rb-rn.$cui";
$keyfile = File::Spec->catfile($keydir, $file);
$config  = File::Spec->catfile('t', 'config', 'defconfig.snomedct.par-chd-rb-rn');
$output = `$perl $util_prg --config $config $cui 2>&1`;

if(-e $keyfile) {
    ok (open KEY, $keyfile) or diag "Could not open $keyfile: $!";
    my $key = "";
    while(<KEY>) { $key .= $_; } close KEY;
    cmp_ok($output, 'eq', $key);
}
else {
    ok(open KEY, ">$keyfile") || diag "Could not open $keyfile: $!";
    print KEY $output;
    close KEY;
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}

#######################################################################################
#  check msh par-chd tests for cui
#######################################################################################
$cui    = "C0018563";
$file    = "getExtendedDef.msh.par-chd.$cui";
$keyfile = File::Spec->catfile($keydir, $file);
$config  = File::Spec->catfile('t', 'config', 'defconfig.msh.par-chd');
$output = `$perl $util_prg --config $config $cui 2>&1`;

if(-e $keyfile) {
    ok (open KEY, $keyfile) or diag "Could not open $keyfile: $!";
    my $key = "";
    while(<KEY>) { $key .= $_; } close KEY;
    cmp_ok($output, 'eq', $key);
}
else {
    ok(open KEY, ">$keyfile") || diag "Could not open $keyfile: $!";
    print KEY $output;
    close KEY;
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}

#######################################################################################
#  check default
#######################################################################################
$cui    = "C0018563";
$file    = "getExtendedDef.default.$cui";
$keyfile = File::Spec->catfile($keydir, $file);
$output = `$perl $util_prg $cui 2>&1`;

if(-e $keyfile) {
    ok (open KEY, $keyfile) or diag "Could not open $keyfile: $!";
    my $key = "";
    while(<KEY>) { $key .= $_; } close KEY;
    cmp_ok($output, 'eq', $key);
}
else {
    ok(open KEY, ">$keyfile") || diag "Could not open $keyfile: $!";
    print KEY $output;
    close KEY;
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}
