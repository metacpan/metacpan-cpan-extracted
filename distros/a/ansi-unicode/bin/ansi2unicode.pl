#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib "$FindBin::Bin/../lib";
use ANSI::Unicode;

#
# convert an ANSI file to unicode, suitable for display in irssi/mirc or html
# usage: ansi2unicode.pl inputfile [--nocolor] [-f format] [-c cols] [outputfile]
#                        -c = number of columns to output, 80 by default
#                        -f = format, currently only html and irc supported, default is irc
#                outputfile = filename to output to

# parse options
my $no_color = 0;
my $format;
my $cols;
GetOptions(
    "format|f=s" => \$format,
    "cols|c=i" => \$cols,
    "nocolor=i" => \$no_color,
);

my $infilename = shift @ARGV;
die "Input filename required\n" unless $infilename;

# convert
my %opts = (
    input_filename => $infilename,
);
$opts{format} = $format if $format;
$opts{cols} = $cols if $cols;
$opts{no_color} = $no_color if defined($no_color);
my $a2u = ANSI::Unicode->new(%opts);

my ($infh, $in);
open($infh, $infilename) or die "Could not open $infilename: $!\n";
{ local $/; $in = <$infh>; close($infh); }
die "no input" unless $in;
my $out = $a2u->convert($in) or return;

############ OUTPUT ##############
my $outfilename = shift @ARGV;
my $output_fh;
if ($outfilename) {
    open($output_fh, ">$outfilename") or die "Could not write to file $outfilename: $!\n";
} else {
    open($output_fh, ">&=", STDOUT);
}
print $output_fh $out;
close $output_fh;
