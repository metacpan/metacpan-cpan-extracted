#!/usr/bin/perl
# run examples test suite, 'text' or 'PDF' output
# this needs to be run from the package root: tools/3_examples.pl [args]
#   because it gets files from examples/resources/
#
# author: Phil M Perry
#

use strict;
use warnings;

our $VERSION = '1.07'; # VERSION
our $LAST_UPDATE = '1.07'; # manually update whenever code is changed

# defaults
my $type      = '-cont';  # continuously run tests without pausing
my $test_type = 'PDF';  # all tests in a subdirectory of examples/

# dependent on optional packages:
my $TH_installed = 1; # Text::Hyphen IS installed and you want to use it.
                      # will produce poor results if it's not installed!
		      # set to 1 if you don't mind running without package.

# command line flags (max one): 
#   -step  = stop after each test to let the tester look at the PDF file
#   -cont  = (default) run continuously to the end, to not tie up tester
my $pause;

# if at least one command line arg, see if flag -cont or -step
if (scalar @ARGV > 0) {
    if      ($ARGV[0] eq '-step') {
        $type = '-step';
    } elsif ($ARGV[0] eq '-cont') {
	# default
        $type = '-cont';
    } elsif ($ARGV[0] =~ m/^-/) {
	die "Unknown command line flag '$ARGV[0]'\n";
    }
    splice @ARGV, 0, 1;  # remove command line arg so <> will work
}

# command line run PDF/ or text/ examples (set $test_type)
if (scalar @ARGV > 0) {
    if ($ARGV[0] eq 'PDF' || $ARGV[0] eq 'text') {
	$test_type = $ARGV[0];
    } else {
	print STDERR "Invalid test type '$ARGV[0]' ignored. Using '$test_type'.\n";
    }
    splice @ARGV, 0, 1;  # remove command line arg so <> will work
}

if (scalar @ARGV > 0) {
    print STDERR "Additional command line entries '@ARGV' ignored!\n";
}

my (@example_list, @example_results);

# comment out any blocks of tests you don't want to run
 if ($TH_installed && $test_type eq 'PDF') {
  push @example_list, "PDF/KP.pl";
  # output location when run tools/3_examples.pl
  push @example_results, "create KP.pdf, showing paragraph text formatted into a block of arbitrary-length lines.";

  push @example_list, "PDF/Flatland.pl";
  # output location when run tools/3_examples.pl
  push @example_results, "create Flatland.pdf, showing an excerpt from the novel \"Flatland\", including inserts for images.";

  push @example_list, "PDF/Triangle.pl";
  # output location when run tools/3_examples.pl
  push @example_results, "create Triangle.pdf, showing some shaping using line lengths.";
 }

 $test_type = 'text';   # do character-based, too
 if ($TH_installed && $test_type eq 'text') {
  push @example_list, "text/KP.pl";
  # output location when run tools/3_examples.pl
  push @example_results, "create T_KP.txt, showing paragraph text formatted into a block of arbitrary-length lines.";

  push @example_list, "text/Flatland.pl";
  # output location when run tools/3_examples.pl
  push @example_results, "create T_Flatland.txt, showing an excerpt from the novel \"Flatland\", including insert space for images (but no images).";

  push @example_list, "text/Triangle.pl";
  # output location when run tools/3_examples.pl
  push @example_results, "create T_Triangle.txt, showing some shaping using line lengths.";
 }

# run with perl examples/<file> [args]

my %args;
# if you do not define a file for a test (leave it EMPTY ''), it will be skipped
# if any spaces in a path, make sure double quoted or use escapes
# must match the basename used in @example_list
#
# KP needs ???? command line arguments
# $args{'PDF/KP'} = "whatever";

$pause = '';
# some warnings:
foreach my $test (@example_list) {
    if ($test eq 'PDF/023_cjkfonts') {  ##### not an active example
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
    print "$desc\n";

    system("perl examples/$file $arg");

    if ($type eq '-cont') { next; }
    print "Press Enter to continue: ";
    $pause = <>;
}
