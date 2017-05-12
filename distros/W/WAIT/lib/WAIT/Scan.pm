#                              -*- Mode: Cperl -*- 
# Scan.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Aug 12 14:05:14 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:39 1998
# Language        : CPerl
# Update Count    : 56
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Scan;

use strict;
use Carp;
use DB_File;
use Fcntl;

sub new {
  my $type  = shift;
  my $table = shift;
  my $last  = shift;
  my $code  = shift;
  my ($first, $value);

  bless {table => $table, code  => $code,
         nextk => 1,      lastk => $last}, $type or ref($type);
}

sub _next {
  my $self = shift;

  return () if $self->{nextk} > $self->{lastk};

  # Access to parents deleted list is no good idea. But we want to
  # avoid to copy result of $self->{table}->fetch($self->{nextk}++)
  # just to check if we neet to inclrement $self->{nextk}
  
  while (defined $self->{table}->{deleted}->{$self->{nextk}}) {
    $self->{nextk}++;
    return () if $self->{nextk} > $self->{lastk};
  }
  $self->{table}->fetch($self->{nextk}++);
}

sub next {
  my $self = shift;

  unless ($self->{code}) {
    $self->_next;
  } else {
    my %tattr = $self->_next;
    if (%tattr) {
      if (&{$self->{code}}(\%tattr)) {
        %tattr;
      } else {
        $self->next;
      }
    } else {
      return ();
    }
  }
}

sub close { undef $_[0]}        # force DESTROY

1;
