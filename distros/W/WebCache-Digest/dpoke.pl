#!/usr/bin/perl
use lib ".";

# poke.pl - sample script to illustrate how the WebCache::Digest code can
#           can be used to create Digests for lists of URLs

# $Id: dpoke.pl,v 1.1 1999/03/12 17:55:33 martin Exp martin $

use Getopt::Std;
use WebCache::Digest;

getopts("duv");

$d = new WebCache::Digest;
$d->create(capacity => 1000);

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

  $d->register("GET", $url);
  print "$url\n" if $opt_v;
}

$d->save($ARGV[0]);

print "> time is: " . localtime(time) . "\n" if $opt_d;


=head1 NAME

poke.pl - create Cache Digests from lists of URLs

=head1 SYNOPSIS

  echo http://www.w3.org | dpoke.pl -duv saved-digest
  dpoke.pl saved-digest < old-access-log
  zcat old-access-log.gz | dpoke.pl -v saved-digest

=head1 DESCRIPTION

This program lets you create a Cache Digest from a list of URLs
supplied via STDIN.  This will then be saved to disk.  The list of URLs
can be in Squid log file format (the default), or simply a list of URLs
(when the B<-u> argument is supplied).

=head1 OPTIONS

=over 4

=item -d

Debug mode - causes helpful debugging messages to be printed

=item -u

Input is a list of URLs rather than Squid log file format.

=item -v

Verbose mode - causes each URL being added to the Digest to be printed
to STDOUT.

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

