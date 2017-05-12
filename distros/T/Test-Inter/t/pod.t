#!/usr/bin/perl

#
# Test that the syntax of our POD documentation is valid.
#

use strict;
use Test::More;

# Don't run tests for installs
unless ( $ENV{RELEASE_TESTING} ) {
   plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

eval "use File::Basename";
plan skip_all => "File::Basename required for testing POD" if $@;

# If there is a file pod.ign, it should be a list of filename
# substrings to ignore (any file with any of these substrings
# will be ignored).

# Find the pod.ign file

my($testdir);
if (-f "$0") {
   my $COM = $0;
   $testdir   = dirname($COM);
   $testdir   = '.'  if (! $testdir);
} elsif (-d 't') {
   $testdir   = 't';
} else {
   $testdir   = '.';
}

my @ign = ();
if (-f "$testdir/pod.ign") {
   open(IN,"$testdir/pod.ign");
   @ign = <IN>;
   close(IN);
   chomp(@ign);
}

chdir("..")  if ($testdir eq '.');

if (@ign) {

   my @file = all_pod_files();

   FILE:
   foreach my $file (@file) {
      foreach my $ign (@ign) {
         next FILE  if ($file =~ /\Q$ign\E/);
      }
      pod_file_ok($file);
   }
   done_testing();

} else {
   all_pod_files_ok();
}



