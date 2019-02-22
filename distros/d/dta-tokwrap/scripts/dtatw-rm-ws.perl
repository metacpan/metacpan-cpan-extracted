#!/usr/bin/perl -w

use File::Basename qw(basename);
use Getopt::Long qw(:config no_ignore_case);
use strict;

our $prog   = basename($0);
our $keep_w = 0;
our $keep_s = 0;

##------------------------------------------------------------------------------
## Command-line

our ($help);
GetOptions(##-- General
	   'help|h' => \$help,

	   ##-- I/O
	   'keep-w|w!' => \$keep_w,
	   'keep-s|s!' => \$keep_s,
	   'rm-w|W!' => sub {$keep_w=!$_[1]},
	   'rm-s|S!' => sub {$keep_s=!$_[1]},
	  );

if ($help) {
  print STDERR <<EOF;

Usage: $prog \[OPTIONS] [INPUT_FILE=-]

Options:
  -help       ##-- this help message
  -w , -W     ##-- do/don't keep //w elements (default=don't)
  -s , -S     ##-- do/don't keep //s elements (default=don't)

EOF
  exit 0;
}

##------------------------------------------------------------------------------
## MAIN

##-- buffer input
local $/=undef;
my $buf = <>;

##-- remove selected elements
if (!$keep_w) {
  $buf =~ s{<a\b[^>]*>[^<>]*</a>}{}g; ##-- remove tokenizer-analyses
  $buf =~ s{</?(?:[wa]|moot|toka|cab:\w+)\b[^>]*>}{}g;
}
$buf =~ s{</?s\b[^>]*>}{}g if (!$keep_s);

##-- dump
print $buf;
