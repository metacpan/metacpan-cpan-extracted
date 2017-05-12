#!/usr/local/bin/perl -w 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl access.t'  
##################### We start with some black magic to print on failure.    
use strict;
use warnings;

use Test::More tests => 6;

use File::Spec;
use File::Path;

if(!(-d "t")) {
    
    print STDERR "Error - program must be run from UMLS::Similarity\n";
    print STDERR "directory as : perl t/vector-input.t \n";
    exit;  
}

#  set the key directory (create it if it doesn't exist)
my $keydir = File::Spec->catfile('t','key');
if(! (-e $keydir) )  {
    File::Path->make_path($keydir);
}

#  get the tests
my $input = File::Spec->catfile('t', 'tests', 'utils', 'bigrams');
my $output_index = File::Spec->catfile('t', 'key', 'static', 'index');
my $output_matrix = File::Spec->catfile('t', 'key', 'static', 'matrix');

my $perl     = $^X;
my $util_prg = File::Spec->catfile('utils', 'vector-input.pl');
my $test_index = File::Spec->catfile('utils', 'index');
my $test_matrix = File::Spec->catfile('utils', 'matrix');

system("$perl $util_prg $test_index $test_matrix $input");
   
if(-e $output_index) 
{
	ok (open KEY1, $output_index) or diag "Could not open $output_index: $!";
	my $key1 = "";
	while(<KEY1>) { $key1 .= $_; } close KEY1;

	ok (open KEY2, $test_index) or diag "Could not open $test_index: $!";
	my $key2 = "";
	while(<KEY2>) { $key2 .= $_; } close KEY2;
	cmp_ok($key1, 'eq', $key2);

	File::Path->remove_tree($test_index);
}
else 
{
	if(-e $test_index) 
	{	
		ok(system ("mv $test_index $output_index")) || diag "Could not move the index result. ";
	}
    SKIP: 
	{
		skip ("Generating key, no need to run test", 1);
	}
}

if(-e $output_matrix) 
{
	ok (open KEY3, $output_matrix) or diag "Could not open $output_matrix: $!";
	my $key3 = "";
	while(<KEY3>) { $key3 .= $_; } close KEY3;

	ok (open KEY4, $test_matrix) or diag "Could not open $test_matrix: $!";
	my $key4 = "";
	while(<KEY4>) { $key4 .= $_; } close KEY4;
	cmp_ok($key3, 'eq', $key4);

	File::Path->remove_tree($test_matrix);
}
else 
{
	if(-e $test_matrix) 
	{	
		ok(system ("mv $test_matrix $output_matrix")) || diag "Could not move the matrix result. ";
	}
    SKIP: 
	{
		skip ("Generating key, no need to run test", 2);
	}
}


