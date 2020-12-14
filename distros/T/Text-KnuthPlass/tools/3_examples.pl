#!/usr/bin/perl
# run examples test suite
# roughly equivalent to examples.bat
#   you will need to update the %args list before running
# author: Phil M Perry

use strict;
use warnings;

our $VERSION = '1.04'; # VERSION
my $LAST_UPDATE = '1.03'; # manually update whenever code is changed

# dependent on optional packages:
my $TH_installed = 1; # Text::Hyphen IS installed and you want to use it.
                      # will produce poor results if it's not installed!

# command line:
#   -step  = stop after each test to let the tester look at the PDF file
#   -cont  = (default) run continuously to the end, to not tie up tester
my $pause;

my (@example_list, @example_results);

 if ($TH_installed) {
  push @example_list, "KP.pl";
  push @example_results, "create examples/KP.pdf, showing paragraph text formatted into a block of arbitrary-length lines.";
 }

# run with perl examples/<file> [args]

my %args;
# if you do not define a file for a test (leave it EMPTY ''), it will be skipped
# if any spaces in a path, make sure double quoted or use escapes
#
# KP needs ???? command line arguments
# $args{'KP'} = "whatever";

my $type;
# one command line arg allowed (-cont is default)
if      (scalar @ARGV == 0) {
    $type = '-cont';
} elsif (scalar @ARGV == 1) {
    if      ($ARGV[0] eq '-step') {
        $type = '-step';
    } elsif ($ARGV[0] eq '-cont') {
	# default
        $type = '-cont';
    } else {
	die "Unknown command line argument '$ARGV[0]'\n";
    }
    splice @ARGV, 0, 1;  # remove command line arg so <> will work
} else {
    die "0 or 1 argument permitted. -cont is default.\n";
}

$pause = '';
# some warnings:
foreach my $test (@example_list) {
    if ($test eq '023_cjkfonts') {
        print "$test: to display the resulting PDFs, you may need to install\n";
        print "  East Asian fonts for your PDF reader.\n";
        $pause = ' ';
    }
}
if ($pause eq ' ') {
    print "Press Enter to continue: ";
    $pause = <>;
}

print STDERR "\nStarting example runs...";

my ($i, $arg);
for ($i=0; $i<scalar(@example_list); $i++) {
    my $file = $example_list[$i];
    my $desc = $example_results[$i];

    if (defined $args{$file}) {
	$arg = $args{$file};
	if ($arg eq '') {
	    print "test examples/$file skipped at your request\n";
	    next;
	}
    } else {
        $arg = '';
    }
    print "\n=== Running test examples/$file $arg\n";
    print $desc;

    system("perl examples/$file $arg");

    if ($type eq '-cont') { next; }
    print "Press Enter to continue: ";
    $pause = <>;
}
