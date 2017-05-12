#!/usr/bin/perl -w
use strict;
use warnings qw(FATAL all NONFATAL misc);

use FindBin;
use lib $FindBin::Bin;
use ApacheConfig;

my ($found, $line) = (0);
while (<>) {
  chomp;
  if (s/^(\#)?(AddHandler cgi-script \.cgi\b.*)$/$2/) {
    print STDERR $1 ? "Changed" : "Already OK", ": $2\n";
    $found++;
  } elsif ($line = m{^(\s*<Directory "?/var/www/?"?>)} .. m{^\s*</Directory}) {
    $context = $1 if $line == 1;
    if (my $n = ensure_config("AllowOverride", "All")) {
      $found += $n;
    }
  }
} continue {
  print "$_\n";
}

unless ($found) {
  die "Not found!\n";
}
