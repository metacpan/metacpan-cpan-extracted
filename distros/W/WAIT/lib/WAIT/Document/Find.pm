#!/usr/bin/perl
#                              -*- Mode: Perl -*- 
# $Basename: Find.pm $
# $Revision: 1.4 $
# Author          : Ulrich Pfeifer
# Created On      : Mon Sep 16 19:04:37 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Wed Nov  5 16:50:40 1997
# Language        : CPerl
# Update Count    : 48
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
# 
# 

package WAIT::Document::Find;
@ISA = qw(WAIT::Document::Base);
require WAIT::Document::Base;

use FileHandle;
use strict;
use Carp;

sub TIEHASH {
  my $type    = shift;
  my $pred    = shift;
  my @files   = @_;

  unless (ref($pred) =~ /CODE/) {
    croak "USAGE: tie %HASH, WAIT::Document::Find, coderef, file, ...";
  }
  my $self   = {
                Pred   => $pred,
                Files  => \@files
               };
  bless $self, ref($type) || $type;
}

sub FETCH {
  my $self = shift;
  my $path = shift;

  return undef unless defined $path;
  return undef unless -f $path;

  my $fh = new FileHandle "< $path";
  
  local($/) = undef;
  <$fh>;
}

sub FIRSTKEY {
  my $self = shift;
  $self->{Pending} = [@{$self->{Files}}];
  $self->NEXTKEY;
}

sub NEXTKEY {
  my $self = shift;
  return undef unless @{$self->{Pending}};
  my $next = pop @{$self->{Pending}};
  while ($next and -f $next) {
    if (&{$self->{Pred}}($next)) {
      return $next;
    }
    $next = pop @{$self->{Pending}};
  }
  if ($next and -d $next) {
    push @{$self->{Pending}}, _expand($next);
  }
  return $self->NEXTKEY;
}

sub _expand {
  my $dir = shift;
  my @result;
  return () unless -d $dir;
  opendir(DIR, $dir) or return ();
  @result = map "$dir/$_", grep $_ !~ /^\.\.?$/, readdir(DIR);
  closedir DIR;
  return @result;
}

sub close {
  my $self = shift;

  delete $self->{Pred};
  delete $self->{Pending};
  delete $self->{Files};        # no need at query time
}

1;
