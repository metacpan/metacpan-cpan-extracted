#!/usr/local/bin/perl

use strict;
use warnings;

use VCS::Lite;
use Getopt::Long;

my $uflag = 0;

GetOptions(
	'universal+' => \$uflag,
	);

if (@ARGV != 2) {
	print <<END;

Usage: $0 [options] file1 file2

Options can be:

	-u	output in diff -u format

END
	exit;
}

my $el1 = VCS::Lite->new(shift @ARGV);
my $el2 = VCS::Lite->new(shift @ARGV);

my $dt1 = $el1->delta($el2);
my $diff = $uflag ? $dt1->udiff : $dt1->diff;

print $diff;
