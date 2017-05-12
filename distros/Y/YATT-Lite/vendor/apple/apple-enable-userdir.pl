#!/usr/bin/perl -w
use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use ApacheConfig;

our $context = "";
my ($line);
while (<>) {
  chomp;
  if ($line = m{^\#?(\Q<Directory "/Users/\E[^/]+/Sites/">)}
	   .. m{^\#?</Directory}) {
    $context = $1 if $line == 1;
    s/^\#//;
    set_config("AllowOverride", "All");
    ensure_config("Options", "ExecCGI");
  }
} continue {
  print "$_\n";
}
