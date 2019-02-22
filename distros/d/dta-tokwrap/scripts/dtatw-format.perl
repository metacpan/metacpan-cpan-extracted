#!/usr/bin/perl -w

use File::Basename qw(basename);
use Getopt::Long qw(:config no_ignore_case);
use XML::LibXML;
use strict;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = basename($0);
our $use_libxml  = 1;
our $keep_blanks = 0;

our $lb_newlines = 1;

our $outfile = '-';

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
our ($help);
GetOptions(##-- General
	   'help|h' => \$help,

	   ##-- I/O
	   'newlines|n|lb|l!' => \$lb_newlines,
	   'N|L' => sub {$lb_newlines=!$_[1]},

	   'xml|x!' => \$use_libxml,
	   'X' => sub {$use_libxml=!$_[1]},

	   'blanks|b!' => \$keep_blanks,
	   'B' => sub {$keep_blanks=!$_[1]},

	   'output|out|o=s' => \$outfile,
	  );

if ($help) {
  print STDERR <<EOF;

Usage: $prog \[OPTIONS] [INPUT_FILE=-]

Options:
  -help       ##-- this help message
  -x , -X     ##-- do/don't pre-format with libxml (default=do)
  -b , -B     ##-- do/don't keep blanks for libxml formatting (default=don't)
  -n , -N     ##-- do/don't insert newlines after <lb/> elements (default=do)

EOF
  exit 0;
}

##-- args
my $infile = @ARGV ? shift : '-';
my ($buf);

if ($use_libxml) {
  ##-- pre-format with libxml
  my $parser = XML::LibXML->new(keep_blanks=>$keep_blanks,load_ext_dtd=>0,validation=>0,expand_entities=>1,recover=>0)
    or die("$prog: could not create XML::LibXML parser: $!");
  my $xdoc = ($infile eq '-' ? $parser->parse_fh(\*STDIN) : $parser->parse_file($infile))
    or die("$prog: could not parse input file '$infile': $!");
  $buf = $xdoc->toString(1);
}
else {
  ##-- just buffer source file
  local $/=undef;
  open(XML,$infile) or die("$prog: open failed for '$infile': $!");
  binmode(XML,':raw');
  $buf = <XML>;
  close(XML) or die("$prog: close failed for $infile: $!");
}

##-- insert newlines into $buf
$buf =~ s{(<[lp]b\b[^>]*/>)(?!\R)}{$1\n}sg if ($lb_newlines);

##-- dump output
open(OUT,">$outfile") or die("$prog: open failed for output file '$outfile': $!");
binmode(OUT,":raw");
print OUT $buf;
close(OUT) or die("$prog: close failed for output file '$outfile': $!");

