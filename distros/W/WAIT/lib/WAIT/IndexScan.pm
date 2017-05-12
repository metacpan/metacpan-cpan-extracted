#                              -*- Mode: Perl -*- 
# IndexScan.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Aug 12 14:05:14 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:43 1998
# Language        : CPerl
# Update Count    : 65
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::IndexScan;

use strict;
use DB_File;
use Fcntl;

sub new {
  my $type  = shift;
  my $index = shift;
  my $code  = shift;
  my ($first, $tid) = ('', '');

  # find the first key
  if ($index->{dbh}->seq($first, $tid, R_FIRST)) {
    require Carp;
    Carp::croak("Could not open scan");
  }
  # Not sure about this. R_FIRST sets $tid to no-of-records?
  # $index->{dbh}->seq($first, $tid, R_NEXT);
  # register to avoid unnecessary position calls
  $index->{scans}++;

  bless {Index => $index, code  => $code,
         nextk => $first, tid   => $tid}, $type or ref($type);
}

sub next {
  my $self = shift;
  my $dbh  = $self->{Index}->{dbh};
  my ($key, $tid, $ntid);

  if (defined $self->{nextk}) {
    unless ($dbh){
      require Carp;
      Carp::croak("Cannot scan closed index");
    }
    $key = $self->{nextk};

    if ($self->{Index}->{scans} > 1) {
      # Another scan is open. Reset the cursor
      $dbh->seq($key, $tid, R_CURSOR);
    } else {
      $tid = $self->{tid};
    }
    if ($dbh->seq($self->{nextk}, $self->{tid}, R_NEXT)) {
      # current tuple is last one
      delete $self->{nextk};
    }

    my @tuple = split /$;/, $key;
    my %tuple = (_id => $tid);
    for (@{$self->{Index}->{attr}}) {
      $tuple{$_} = shift @tuple;
    }

    if ($self->{code}) {        # test condition
      &{$self->{code}}(\%tuple)? %tuple : $self->next;
    } else {
      %tuple;
    }
  } else {
    return;
  }
}

sub close { undef $_[0]}        # force DESTROY
sub DESTROY {
  shift->{Index}->{scans}--;
}

1;
