#!/usr/bin/perl
# test script for 23-methods, executed in test directory
my $testnum = '23-methods';
my $testfilesdir = "../../testfiles/$testnum";
my $insource = "$testfilesdir/test1.in"; my $inorig = "test1.in";
my $procfile = "test1.txt"; my $outNew = $procfile;
my $outsource = "$testfilesdir/test1.out";
my $outExpected = "test1.out-expected";
mycopy($insource, $inorig);
mycopy($insource, $procfile);
my @sfishArgs = ( $procfile );
starfish_cmd( @sfishArgs);
mycopy($outsource, $outExpected);
comparefiles($outExpected, $outNew);

1;

