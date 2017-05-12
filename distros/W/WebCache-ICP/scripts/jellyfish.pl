#!/usr/bin/perl

# jellyfish.pl - 'fake' ICP server for integrating mirror sites with caches
# $Id: jellyfish.pl,v 1.1 1999/04/27 16:44:39 martin Exp $

# Copyright (c) 1999 Martin Hamilton.  All rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use Getopt::Std;
use WebCache::ICP;

@magic = ();

foreach $specfile (@ARGV) {
  open (IN, $specfile) || die "$0: couldn't open spec file $specfile: $!";
  chop($mirror = <IN>);
  while(<IN>) {
    chop;
    $_ =~ s/\/$//; # normalise to no trailing slashes
    # XXX dumb - but this is only a prototype :-)
    push(@magic, $_);
  }
  close(IN);
}

$i = new WebCache::ICP;
$i->server ( port => 3131, callback => \&mirror );


# this callback is executed for each request received
sub mirror {
  my ($self, $fd, $sin, $response) = @_;
  my ($url);

  $self = $self->burst($response);

  print "url: " . $self->payload . "\n";
  $url = $self->payload;
  $url =~ s/^....//;
  $self->payload($url);

  if ( &is_mirrored($self->payload) ) {
    $self->opcode("OP_HIT");
  } else {
    $self->opcode("OP_MISS_NOFETCH");
  }

  $self->send ( fd => $fd, sin => $sin );
}


# dumb-ass way of checking to see if a given URL is in our mirror
sub is_mirrored {
  my ($url) = @_;

  # XXX should clean up URL before doing regexp match on it
  foreach $site (@magic) {
    next unless $url =~ /^$site/; # first match wins
    return 1;
  }
  return 0;
}

