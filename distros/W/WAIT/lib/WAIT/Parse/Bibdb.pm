#                              -*- Mode: Perl -*- 
# Bibdb.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Sep  5 16:17:38 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:42 1998
# Language        : CPerl
# Update Count    : 50
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Parse::Bibdb;
require WAIT::Parse::Base;
use strict;
use vars qw(@ISA);

@ISA = qw(WAIT::Parse::Base);

sub split {                     # called as method
  my %result;
  my $fld;

  for (split /\n/, $_[1]) {
    if (s/^(\S+):\s*//) {
      $fld = lc $1;
      $result{$fld} = '' unless exists $result{$fld} # -w
    }
    $result{$fld} .= WAIT::Filter::detex($_) if defined $fld;
  }
  return \%result;              # we go for speed
}


sub tag {                       # called as method
  my @result;
  my $tag;
  
  for (split /\n/, $_[1]) {
    next if /^\w\w:\s*$/;
    if (s/^(\S+)://) {
      push @result, {_b => 1}, "$1:";
      $tag = lc $1;
    }
    if (defined $tag) {         # detex changes character positions;
                                # it *must* be applied therefore
      push @result, {$tag => 1}, WAIT::Filter::detex("$_\n");
    } else {
      push @result, {}, WAIT::Filter::detex("$_\n");
    }
  }
  return @result;               # we don't go for speed
}

# Cusomized filters
package WAIT::Filter;
  
sub cctr {
  my $text = shift;
  $text =~ tr/A-Z/a-z/;
  $text =~ tr/a-z0-9./ /c;      # don't squeeze
  $text;
}

# Filter changes character position. It *must* be applied in the
# tagging function to yield propper hilighting!
sub detex {                     
  local($_) = @_;

  return '' unless defined $_;
  s/\\\"a/\344/g;               # ä
  s/\\\"A/\344/g;               # ä
  s/\\\"o/\366/g;               # ö
  s/\\\"O/\366/g;               # ö
  s/\\\"u/\374/g;               # ü
  s/\\\"U/\374/g;               # ü
  s/\\\"s/\337/g;               # ß
  s/\\ss\{\}/\337/g;            # ß
  $_;
}

1;

