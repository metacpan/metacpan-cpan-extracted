#!/usr/bin/perl

# starfish.pl - simple Squid redirector to integrate mirror sites
# $Id: starfish.pl,v 1.2 1999/04/27 16:59:07 martin Exp $

# Copyright (c) 1999 Martin Hamilton.  All rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# you'll need to change this directory!
chdir("/usr/local/mirrors");

$|=1;

@specfiles = `ls`;
@magic = ();

foreach $specfile (@specfiles) {
  open (IN, $specfile) || die "$0: couldn't open spec file $specfile: $!";
  chop($mirror = <IN>);
  while(<IN>) {
    chop;
    $_ =~ s/\/$//; # normalise to no trailing slashes
    # XXX dumb - but this is only a prototype :-)
    $magic{$_} = $mirror;
  }
  close(IN);
}

while(<>) {
  chop;
  s/ \s+/ /g;
  ($url, $addr_fqdn, $ident, $method) = split(/ /);

  $nurl = &mirror($url);
  print "$nurl $addr_fqdn $ident $method\n";
  #print STDERR "$nurl $addr_fqdn $ident $method\n";
}


# dumb-ass way of checking to see if a given URL is in our mirror
sub mirror {
  my ($url) = @_;

  # XXX should clean up URL before doing regexp match on it

  while (($site, $mirror) = each %magic) {
    next unless $url =~ /^$site/; # first match wins
    $url =~ s/^$site/$mirror/;
    last;
  }
  return $url;
}

