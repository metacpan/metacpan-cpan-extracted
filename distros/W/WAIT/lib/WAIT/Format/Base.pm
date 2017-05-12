#                              -*- Mode: Perl -*- 
# Base.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Sep 18 19:04:42 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:46 1998
# Language        : CPerl
# Update Count    : 49
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Format::Base;
use strict;

sub new {
  my $type = shift;
  my %parm = @_;

  bless \%parm, ref($type) || $type;
}

sub text {
  $_[1];
}

sub bold {
  join '', map "$_$_", grep length($_), split /(.)/, $_[1];
}

sub italic {
  join '', map "_$_", grep length($_), split /(.)/, $_[1];
}

sub query {
  join '', map "$_$_", grep length($_), split /(.)/, $_[1];
}

sub as_string {
  my $self   = shift;
  my $text   = shift;
  my $result = '';
  my $i;
  
  for ($i=0; $i < @$text; $i+=2) {
    my %tag = %{$text->[$i]};
    my $txt = $text->[$i+1];

    next unless length($txt);
    if (exists $tag{'_qt'}) {
      $result .= $self->query($txt);
      #my @line = split ' ', $txt, 2;
      #$result .= $self->query(shift @line);
      #next unless @line;
      #$result .= ' ';
      #$result .= shift @line;
    } elsif (exists $tag{'_b'}) {
      $result .= $self->bold($self->text($txt));
    } elsif (exists $tag{'_i'}) {
      $result .= $self->italic($self->text($txt));
    } else {
      $result .= $self->text($txt);
    }
  }
  $result;
}

1;
