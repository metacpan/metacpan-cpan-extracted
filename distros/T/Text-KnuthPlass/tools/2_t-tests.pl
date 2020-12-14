#!/usr/bin/perl
# run all "t" tests
# roughly equivalent to t-tests.bat
# must be run from parent of t/
# author: Phil M Perry

use strict;
use warnings;

our $VERSION = '1.04'; # VERSION
my $LAST_UPDATE = '1.03'; # manually update whenever code is changed

# command line flags, mutually exclusive:
# -raw   show full output of each t-test run
# -noOK  exclude "ok" lines so can easily spot error lines  DEFAULT

my @test_list = (
	{ 'file' => "00-load",       'flags' => '-T', },
	{ 'file' => "01-nodes",      'flags' => '',   },
	{ 'file' => "02-javascript", 'flags' => '',   },
	{ 'file' => "pod",           'flags' => '-T', },
	{ 'file' => "pod-coverage",  'flags' => '',   },
                );
# override full list above, and run just one or two tests
#@test_list = qw( 02-javascript );

# perl <flags> t/<name>.t will run it

my $type;
# one command line arg allowed (-noOK is default)
if      (scalar @ARGV == 0) {
    $type = '-noOK';
} elsif (scalar @ARGV == 1) {
    if      ($ARGV[0] eq '-raw') {
        $type = '-raw';
    } elsif ($ARGV[0] eq '-noOK') {
	# default
        $type = '-noOK';
    } else {
	die "Unknown command line argument '$ARGV[0]'\n";
    }
} else {
    die "0 or 1 argument permitted. -noOK is default.\n";
}

foreach my $file (@test_list) {
    my $command = $file->{'flags'} . " t/" . $file->{'file'} . ".t";
    my @results = `perl $command`;
    # TBD: detect if a FAILED test, and remark at end if any failures
    print "\nt/$file->{'file'}.t\n";
    if ($type eq '-raw') {
	print "@results";
    } else {
	# -noOK   remove any lines which start with "ok"
	foreach my $line (@results) {
	    if ($line !~ m/^ok/) {
		print $line;
	    }
	}
    }
	
}
