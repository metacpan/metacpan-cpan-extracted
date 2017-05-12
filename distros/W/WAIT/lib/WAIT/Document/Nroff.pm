#                              -*- Mode: Cperl -*- 
# Nroff.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Sep 16 19:04:37 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:48 1998
# Language        : CPerl
# Update Count    : 76
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Document::Nroff;
@ISA = qw(WAIT::Document::Base);
require WAIT::Document::Base;

use FileHandle;
use strict;
#use diagnostics;
use Carp;

sub TIEHASH {
  my $type    = shift;
  my $pipe    = shift;
  my @files   = grep -f $_, @_;
  
  my $self   = {
                Pipe   => $pipe || 'nroff',
                Files  => \@files
               };
  bless $self, ref($type) || $type;
}

#$ENV{PATH} .= ':/usr/local/groff-1.09/bin:/app/sun4_55/unido-inf/groff/1.10/bin';

use File::Basename;

sub catfile ($) {
  my $fullname = shift;
  my  ($name,$path) = fileparse($fullname);
  $path =~ s{man([^/]+)\/$}
            {cat$1/}; 
  "$path$name";
}

sub nroff {
  my $self = shift;
  my $path = shift;

  return undef unless -f $path;

  my $fh = new FileHandle "< $path";
  return undef unless defined $fh;
  my $first = <$fh>;
  $fh->close;
  return undef if $first =~ /^\.so man/;
  return undef unless defined $first;
  $first =~ /\'\\\"\s.*((e)|(t))+/;
  my @pre;
  push @pre, 'eqn -Tascii' if $2;
  push @pre,  'tbl' if $3;
  push @pre, $self->{Pipe};
  my $pipe = pop(@pre) . " $path |";
  if (@pre) {
    $pipe .=  join ('|', @pre) .  '|';;
  }
  local($/) = undef;
  $fh = new FileHandle "$pipe";
  return unless defined $fh;
  <$fh>;
}

sub FETCH {
  my $self = shift;
  my $path = shift;
  my $catp = catfile $path;
  return undef unless defined $path;
  
  local($/) = undef;

  if (-e $catp) {
    my $fh = new FileHandle "< $catp";
    return <$fh>;
  }
  my $cont = $self->nroff($path);
  if ($cont) {
    my $fh = new FileHandle "> $catp";
    if ($fh) {
      warn "Generating $catp\n";
      $fh->print($cont);
    }
  }
  $cont;
}

sub FIRSTKEY {
  my $self = shift;
  $self->{fno} = 0;
  $self->NEXTKEY;
}

sub NEXTKEY {
  my $self = shift;
  return undef if ($self->{fno}++ > @{$self->{Files}});
  $self->{Files}->[$self->{fno}-1];
}

sub close {
  my $self = shift;

  delete $self->{fno};
  delete $self->{Files};        # no need at query time
}

1;
