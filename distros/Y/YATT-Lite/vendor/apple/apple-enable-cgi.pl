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
  if (s/^\s*(\#)?(AddHandler cgi-script \.cgi\b.*)$/$2/) {
    print STDERR $1 ? "Changed" : "Already OK", ": $2\n";
  } elsif ($line = m{^(<Directory "/Library/WebServer/CGI-Executables">)} .. m{^</Directory}) {
    $context = $1 if $line == 1;
    ensure_config("Options", "ExecCGI");
  } elsif ($line = m{^(<Directory "/Library/WebServer/Documents">)} .. m{^</Directory}) {
    $context = $1 if $line == 1;
    ensure_config("AllowOverride", "All");
  }
} continue {
  print "$_\n";
}
