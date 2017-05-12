#                              -*- Mode: Perl -*- 
# CPAN.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Sep 18 19:24:55 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:45 1998
# Language        : CPerl
# Update Count    : 19
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Format::CPAN;
require WAIT::Format::HTML;
use strict;
use vars qw(@ISA);

@ISA = qw(WAIT::Format::HTML);

my $CPAN = 'http://ls6-www.informatik.uni-dortmund.de/ir/cgi-bin/CPAN';

sub as_string {
  my $self = shift;
  my ($text, $func) = @_;

  my $result = $self->SUPER::as_string(@_);

  if ($func) {
    my %rec = &$func();
    if ($rec{source} and $rec{source} !~ m(^/app/unido)) {
      my $base = $rec{source}; $base =~ s:.*/::;
      $result =
        qq[Contained in: <a href="$CPAN/$rec{source}">$base</a><br>\n]
          . $result;
    }
  }
  $result;
}

1;
