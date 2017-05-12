#!/usr/local/bin/perl -w 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl access.t'  
##################### We start with some black magic to print on failure.    
use strict;
use warnings;

use Test::More tests => 5;

use UMLS::Interface;
use File::Spec;
use File::Path;

if(!(-d "t")) {
    
    print STDERR "Error - program must be run from UMLS::Similarity\n";
    print STDERR "directory as : perl t/create-icfrequency.t \n";
    exit;  
}

#  initialize option hash
my %option_hash = ();

#  set the option hash
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

#  set the tests
my $perl       = $^X;
my $util_prg   = File::Spec->catfile('utils', 'create-icfrequency.pl');

#  set the input/outputfile
my $inputfile  = File::Spec->catfile('t','options','plain_text');
my $outputfile = File::Spec->catfile('t','output', 'create-icfrequency.output');

#  remove the output file if it exists
File::Path->remove_tree($outputfile);

#  set the key files
my $filekey    = File::Spec->catfile('t', 'key', $version, 'create-icfrequency.key');
my $commandkey = File::Spec->catfile('t', 'key', $version, 'create-icfrequency.command');

#  run the program	
my $commandline = `$perl $util_prg $outputfile $inputfile 2>&1`;

print "$util_prg $outputfile $inputfile\n";

#  check the output
my $output = "";
open(OUT, $outputfile) || die "Could not open outputfile $outputfile\n";
while(<OUT>) { $output .= $_; } close OUT;

if(-e $filekey) {
    ok (open FKEY, $filekey) or diag "Could not open $filekey: $!";
    my $key = "";
    while(<FKEY>) { $key .= $_; } close FKEY;
    cmp_ok($output, 'eq', $key);
}
else {
    ok(open FKEY, ">$filekey") || diag "Could not open $filekey: $!";
    print FKEY $output;
    close FKEY; 
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}    

#  check the command line
if(-e $commandkey) {
    ok (open CKEY, $commandkey) or diag "Could not open $commandkey: $!";
    my $key = "";
    while(<CKEY>) { $key .= $_; } close CKEY;
    cmp_ok($commandline, 'eq', $key);
}
else {
    ok(open CKEY, ">$commandkey") || diag "Could not open $commandkey: $!";
    print CKEY $commandline;
    close CKEY; 
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}    

#  remove output file
File::Path->remove_tree($outputfile);
