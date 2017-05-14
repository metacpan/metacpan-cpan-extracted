#!/usr/bin/perl -Ilib
use strict;
use Test::Harness;
# $ENV{'HARNESS_PERL_SWITCHES'} = '-d';

my %drivers = (1 => 'Xindice',
	       2 => 'eXist',
	       3 => 'File',
	       );
# default urls
my %urls = (Xindice => 'http://localhost:4080',
	    eXist => 'http://localhost:8081',
	    File => './t/file',
	    );

my $driver = 0;

while(! $driver){
    print "Please select the database you wish to test:\n";
    foreach(keys %drivers){
	print "$_ $drivers{$_}\n";
    }
    print "Note that (apart from File) the database must be running to use the tests\n";
    print "Driver number: ";
    my $no = <STDIN>;
    chomp $no;
    if (defined $drivers{$no}){
	$driver = $drivers{$no};
    }
    else{
	print "Driver $no is not available\n";
    }
}
$ENV{'DRIVER'} = $driver;

my $url = $urls{$driver};
print "New url for db? [$url]: ";
my $new_url = <STDIN>;
chomp $new_url;

$ENV{'URL'} = $new_url ? $new_url: $url;

print "Continuing with $driver driver at $ENV{'URL'} ...\n";

opendir TESTDIR,'t' or die "No test directory\n";

my @tests = ();
my @files = readdir TESTDIR;

foreach(@files){
        if ($_ =~ /\d+_ini\.t$/){
                push @tests, "t/$_";
                }
        }
my @sorted_tests = sort(@tests);
die "No .t files in test directory\n" unless $sorted_tests[0];

# my @sorted_tests;
# push @sorted_tests, 't/01_ini.t';
$Test::Harness::verbose = 1;
runtests(@sorted_tests);



