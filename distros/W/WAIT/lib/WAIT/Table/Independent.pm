#                              -*- Mode: Cperl -*- 
# Independent.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Fri Sep 13 14:00:37 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:36 1998
# Language        : CPerl
# Update Count    : 5
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Table::Independent;
use vars qw(@ISA);

@ISA = qw(WAIT::Table);

sub fetch {
  my $self = shift;
  my $key   = shift;
  my $name = $self->{name};

  my %tattr = $self->SUPER::fetch($key);
  if (%tattr) {
    $tattr{'_ee'} = "$name$key";
  }
  %tattr;
}

sub insert {
  my $self   = shift;
  my $weight = shift;

  $self->SUPER::insert(_weight => $weight, @_);
}

