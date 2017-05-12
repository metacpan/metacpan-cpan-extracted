package inc::dtRdrBuilder::AlsoPodCoverage;

use warnings;
use strict;

# Copyright (C) 2007 by Eric Wilhelm and OSoft, Inc.
# License: perl

# ugh, Pod::Coverage doesn't fail when require fails.  Also, it can't
# check the other-platform's pod coverage.  That's just not acceptable.

use base 'Pod::Coverage';

# Hmm, I'm assuming it is in lib because it usually is.  Maybe just
# don't use Pod::Coverage as a base?  If you're worried about this
# missing multi-package modules, quit writing multi-package modules
# because we would have to decide what pod covered what package.

sub _get_syms {
  my $self    = shift;
  my $package = shift;

  my $file = 'lib/' . $package . '.pm';
  $file =~ s#::#/#g;
  unless(-e $file) {
    die "cannot find $file";
  }

  open(my $fh, '<', $file) or die "cannot open $file";

  my @found;
  while(my $line = <$fh>) {
    if($line =~ m/^sub ([a-z_]\w+)/) {
      my $name = $1;
      # TODO skip one-liners?
      next if $self->_private_check($name);
      push(@found, $1);
    }
  }

  return @found;
  
}

# vi:ts=2:sw=2:et:sta
1;
