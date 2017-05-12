#                              -*- Mode: Perl -*- 
# HTML.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Sep 18 19:24:55 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:45 1998
# Language        : CPerl
# Update Count    : 14
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Format::HTML;
require WAIT::Format::Base;
use strict;
use vars qw(@ISA);

@ISA = qw(WAIT::Format::Base);

my %DEFAULT = (
               bold_s   => '<B>',
               bold_e   => '</B>',
               query_s  => '<B><FONT COLOR="#ff0000">', # SIZE="+2"
               query_e  => '</FONT></B>',
               italic_s => '<I>',
               italic_e => '</I>',
              );
sub new {
  my $type = shift;
  my %parm = @_;
  my %self = %DEFAULT;
  
  for (keys %DEFAULT) {
    $self{$_} = $parm{$_} if exists $parm{$_};
  }
  bless \%self, ref($type) || $type;
}

sub bold {
  my $self = shift;
  $self->{bold_s} . $_[0] . $self->{bold_e};
}

sub italic {
  my $self = shift;
  $self->{italic_s} . $_[0] . $self->{italic_e};
}

sub query {
  my $self = shift;
  $self->{query_s} . $_[0] . $self->{query_e};
}

use HTML::Entities;

sub text {
  encode_entities($_[1]);
}

sub as_string {
  my $self   = shift;

  "<PRE>\n" . $self->SUPER::as_string(@_) . "\n</PRE>\n";
}

1;
