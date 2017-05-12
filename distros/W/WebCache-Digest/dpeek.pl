#!/usr/bin/perl
use lib ".";

# peek.pl - sample script to illustrate how the WebCache::Digest code can
#           can be used to look up URLs in cache digests downloaded off
#           the Net or uploaded from disk

# $Id: dpeek.pl,v 1.1 1999/03/12 17:55:33 martin Exp martin $

use Getopt::Std;
use WebCache::Digest;

getopts("dhuv");

$d = new WebCache::Digest;

if ($#ARGV == 1) {
  $host = $ARGV[0] || "localhost",
  $port = $ARGV[1] || "3128";

  $d->fetch(host => $host, port => $port);
  print "> fetching digest from $host:$port\n" if $opt_d;
} elsif ($#ARGV == 0)  {
  $d->load($ARGV[0]);
  print "> loading from $ARGV[0]\n" if $opt_d;
}

print STDOUT $d->dump_header if $opt_d || $opt_h;
exit if $opt_h;

$|=1;

print "> time is: " . localtime(time) . "\n" if $opt_d;

while(<STDIN>) {
  chop;
  s/\s+/ /g;
  if ($opt_u) {
    $url = $_;
  } else {
    @bits = split;
    $url = $bits[6];
  }

  if ($opt_v) {
    if ($d->lookup("GET", $url)) {
      print "HIT  $url\n";
    } else {
      print "MISS $url\n";
    }
  } else {
    $d->lookup("GET", $url);
  }
}

print "> time is: " . localtime(time) . "\n" if $opt_d;


=head1 NAME

peek.pl - look up URLs in Cache Digests

=head1 SYNOPSIS

  echo http://www.w3.org | dpeek.pl -duv reboot.wwwcache.ja.net 3128
  dpeek.pl -h saved-digest < old-access-log
  zcat old-access-log.gz | dpeek.pl -v saved-digest

=head1 DESCRIPTION

This program lets you look up URLs (the HTTP 'GET' method is assumed)
in Cache Digests which are either fetched via HTTP or loaded from a
file.  The list of URLs should be supplied via STDIN, and can be in
Squid log file format (the default), or simply a list of URLs (when
the B<-u> argument is supplied).

=head1 OPTIONS

=over 4

=item -d

Debug mode - causes helpful debugging messages to be printed

=item -h

Print the Digest header details out, e.g. version number and number
of URLs in Digest, then exit.

=item -u

Input is a list of URLs rather than Squid log file format.

=item -v

Verbose mode - causes each URL being looked up to be printed to STDOUT,
along with a hit/miss indicator.

=back

=head1 COPYRIGHT

Copyright (c) 1999, Martin Hamilton.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

It was developed by the JANET Web Cache Service, which is funded by
the Joint Information Systems Committee (JISC) of the UK Higher
Education Funding Councils.

=head1 AUTHOR

Martin Hamilton E<lt>martinh@gnu.orgE<gt>

