#!/usr/bin/perl -w
#
# perl -i $this_script /etc/httpd/conf/httpd.conf
#

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use ApacheConfig;

our $context = "";
my ($line);
while (<>) {
  chomp;
  if (s/^\s*(\#)?\s*(AddHandler cgi-script \.cgi\b.*)$/$2/) {
    print STDERR $1 ? "Changed" : "Already OK", ": $2\n";
  } elsif ($line = m{^(<Directory "/var/www/cgi-bin">)} .. m{^</Directory}) {
    $context = $1 if $line == 1;
    ensure_config("Options", "ExecCGI");
  } elsif ($line = m{^(<Directory "/var/www/html">)} .. m{^</Directory}) {
    $context = $1 if $line == 1;
    ensure_config("AllowOverride", "All");
  }
} continue {
  print "$_\n";
}
