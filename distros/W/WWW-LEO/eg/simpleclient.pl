#!/usr/bin/env perl

# simpleclient.pl 0.01 -- Simple-minded sample client for the WWW::LEO module
# Copyright (C) 2002 Jörg Ziefle
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.)

use warnings;
use strict;
use WWW::LEO;
my $COLWIDTH = 35;

my $COLWIDTH_DOTS = $COLWIDTH-3;
my $leo = WWW::LEO->new;
$leo->query("@ARGV"||usage());
if ($leo->num_results) {
  my $i;
  foreach my $resultpair (@{$leo->en_de}) {
    printf "%3d: %-${COLWIDTH}s %-${COLWIDTH}s\n", ++$i, map { s/^(.{$COLWIDTH_DOTS}).+$/$1.../; $_ } @$resultpair;
  }
} else {
  print "Sorry, your query gave no results.\n";
}

sub usage {
  $0 =~ s,.*/,,;
  print STDERR "Usage: $0 <query>\n";
  exit 0;
}
