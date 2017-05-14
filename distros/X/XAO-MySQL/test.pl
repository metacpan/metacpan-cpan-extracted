#!/usr/bin/perl
##
# Processing all tests in testcases in random (!) order.
#
# Alternatively you can say:
#  ./test.pl placeholders fields
# to test only "placeholders" and "fields".
#
eval "use XAO::FS";
if($@) { die "Can't find XAO::FS - call as ``perl -Mblib $0''\n" }

##
# List of exceptions that are in testcases, but are not test cases.
#
my @exceptions=qw(base dbh);

##
# Building the list of tests we want to run. If some test names are
# provided on command line - great, use them.
#
my @files=@ARGV ? @ARGV : <testcases/*.pm>;
my @tests;
foreach my $test (@files) {
    $test=$2 if $test=~/(testcases\/)?(.*?)(\.pm)$/;
    next if grep(/$test/,@exceptions);
    push(@tests,$test);
}

##
# Randomizing tests list order to make sure that tests do not depend on
# each other.
#
for(my $i=0; $i!=@tests; $i++) {
    push(@tests,splice(@tests,rand(@tests),1));
}

##
# Preparing test files. This looks stupid and probably is stupid, but I
# do not know any simpler way to use Test::Harness.
#
my $testdir='ta';
mkdir "$testdir",0755 || die "Can't make directory: $!\n";
foreach my $test (@tests) {
    open(F,"> $testdir/$test.t") || die "Can't create test script ($testdir/$test.t): $!\n";
    print F <<EOT;
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
use strict;
use Test::Unit::HarnessUnit;

my \$r=Test::Unit::HarnessUnit->new();
\$r->start('testcases::$test');
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
EOT
    close(F);

    open(F,"> $testdir/$test.pl") || die "Can't create test script ($testdir/$test.pl): $!\n";
    print F <<EOT;
#!$^X
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
use strict;
use blib;
use XAO::Utils;
use Test::Unit::TestRunner;

XAO::Utils::set_debug(1);

my \$r=Test::Unit::TestRunner->new();
\$r->start('testcases::$test');
print "\n";
#### GENERATED AUTOMATICALLY, DO NOT EDIT ####
EOT
    close(F);
    chmod 0755, '$testdir/$test.pl';
}

##
# Executing tests
#
use Test::Harness;
print STDERR <<'END_OF_WARNING';
============================================================
Some of the tests may take up to a couple of minutes to run.
Please be patient.

If you see that a test failed, please run it as follows:
   perl -w ta/failed_test_name.pl

That will show you details about failure. Send the output
to am@xao.com along with your perl version, database driver
and version and short description of what you think might
be the reason.
============================================================
END_OF_WARNING
runtests(map { "$testdir/$_.t" } @tests);

##
# Done!
###############################################################################
