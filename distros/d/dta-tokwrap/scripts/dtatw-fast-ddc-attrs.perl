#!/usr/bin/perl -w

use File::Basename qw(basename);
use Getopt::Long qw(:config no_ignore_case);
use strict;

##------------------------------------------------------------------------------
## Command-line
our $prog = basename($0);
our $outfile = '-';
our $keep_b = 0;
our $keep_xb = 0;
our ($help);
GetOptions(##-- General
	   'help|h' => \$help,
	   'o|out|output=s' => \$outfile,
	   'b|keep-b!' => \$keep_b,
	   'xb|keep-xb!' => \$keep_xb,
	  );
if ($help) {
  print STDERR <<EOF;

Usage: $prog \[OPTIONS] T_XML_FILE

Options:
  -h, -help          # this help message
  -o, -out OUTFILE   # output file (t-xml with //w/\@ws)
      -[no]keep-b    # do/don't keep //w/\@b (default: don't)
      -[no]keep-xb   # do/don't keep //w/\@xb (default: don't)

Description:
 Fast regex heuristics for extracting //w/\@ws from TokWrap *.t.xml files.

EOF
  exit ($help ? 0 : 1);
}

##======================================================================
## MAIN

##-- initialize: @ARGV
push(@ARGV,'-') if (!@ARGV);

##-- initialize output file(s)
$outfile = '-' if (!defined($outfile));
my ($outfh);
open($outfh, ">$outfile")
  or die("$prog: ERROR: open failed for output file '$outfile': $!");

##-- tweak input file(s)
my ($cur);   ##-- current (text) byte-offset
my ($off,$len,$ws);

foreach my $infile (@ARGV) {
  $prog = basename($0).": $infile";

  open(my $infh,"<$infile")
    or die("$prog: ERROR: open failed for input file '$infile': $!");
  $cur = -1;
  while (defined($_=<$infh>)) {
    if (/^\s*<w.*?\sb=\"([0-9]+) ([0-9]+)\"/) {
      ($off,$len) = ($1,$2);
      $ws         = ($off==$cur ? 0 : 1);
      $cur        = $off+$len;
      s{(/?>)}{ ws="$ws"$1};
      s{\sb=\"[^\"]*\"}{}g if (!$keep_b);
      s{\sxb=\"[^\"]*\"}{}g if (!$keep_xb);
    }
    print $outfh $_;
  }
  close $infh;
}
close($outfh)
  or die("$prog: close failed for '$outfile': $!");

