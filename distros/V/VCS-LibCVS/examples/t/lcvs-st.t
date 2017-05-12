# -*- CPerl -*-
#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

#########################
# Test lcvs-st
#########################

# This script should be in a directory called t and should be run from the
# parent directory of that.  It will test the lcvs-st in its parent directory.
# It looks for various things under that assumption.

# The test creates a repository and sandboxes, which is fairly time intensive.
# If you want to save this time, set LCVS_ST_T_TEST_REPO_DIR to a directory
# name which you want to use.  If the directory exists it will be reused.  Be
# careful if you change the directory, or upgrade the script, because this may
# break the tests.  It's also useful if tests are failing, and you want to
# check out the contents of the repository to find out why, since it won't be
# removed.

# Please excuse the shell scripty stuff here.

use strict;
use Test;

use File::Spec;
use File::Temp qw/ tempdir /;

BEGIN { plan tests => 111 }

# Find the directory where this script is.
my ($vol, $dirname, $exename) = File::Spec->splitpath($0);
$dirname = File::Spec->rel2abs( $dirname );

# set up the test repository
my $base = (    $ENV{LCVS_ST_T_TEST_REPO_DIR}
            || tempdir("libcvs-lcvs_st_t-XXXXXX", TMPDIR => 1, CLEANUP => 1));
system("chmod +x $dirname/lcvs-st.t-setup.sh");
ok(! system("$dirname/lcvs-st.t-setup.sh $base"));

# get the right lcvs-st and include path

my $lcvs_st = "perl -I$dirname/../../blib/lib $dirname/../lcvs-st";

# Check that the results are all there, and that the status is reported
# correctly.  Files are named the same as their expected results.

# All of the files that should be found by lcvs-st.  They are named after their
# status as it should be reported by lcvs-st.

my @expected_files = ( "ABM", "ABU", "AUM", "AUU",
                       "NMM", "NMU", "NUM",
                       "RMB", "RMM", "RMU", "RUB", "RUM", "RUU",
                       "UBB", "UBM", "UBU", "UCB", "UCC", "UCM", "UCU",
                       "UMB", "UMC", "UMM", "UMU", "UUB", "UUM", "UUU" );

# First set of tests, just invoke it in the directory
{
  my $results = `cd $base/sandbox1/dir1; $lcvs_st`;
  my @result_lines = split (/\n/, $results);

  ok(scalar @result_lines, scalar @expected_files) || exit 1;

  foreach my $file (@expected_files) {
    ok (shift (@result_lines), "$file $file");
  }
}

# Second set of tests, invoke it for each expected file

foreach my $file (@expected_files) {
  ok(`cd $base/sandbox1/dir1; $lcvs_st $file`, "$file $file\n");
}

# Third set of tests, just invoke it in a subdirectory
{
  my $results = `cd $base/sandbox1; $lcvs_st dir1`;
  my @result_lines = split (/\n/, $results);

  ok(scalar @result_lines, scalar @expected_files) || exit 1;

  foreach my $file (@expected_files) {
    ok (shift (@result_lines), "$file dir1/$file");
  }
}

# Fourth set of tests, invoke it in a subdirectory for each expected file

foreach my $file (@expected_files) {
  ok(`cd $base/sandbox1; $lcvs_st dir1/$file`, "$file dir1/$file\n");
}
