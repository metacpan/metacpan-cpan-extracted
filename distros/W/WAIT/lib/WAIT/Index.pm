#                              -*- Mode: Cperl -*- 
# Index.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Aug  8 13:05:10 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:43 1998
# Language        : CPerl
# Update Count    : 107
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Index;
use WAIT::IndexScan;
use strict;
use DB_File;
use Fcntl;

sub new {
  my $type = shift;
  my %parm = @_;
  my $self = {};

  unless ($self->{file} = $parm{file}) {
    require Carp;
    Carp::croak("No file specified");
  }
  unless ($self->{attr} = $parm{attr}) {
    require Carp;
    Carp::croak("No attributes specified");
  }
  bless $self, ref($type) || $type;
}

sub drop {
  my $self = shift;
  if ((caller)[0] eq 'WAIT::Table') { # Table knows about this
    my $file = $self->{file};
    ! (!-e $file or unlink $file);
  } else {                            # notify our database
    require Carp;
    Carp::croak(ref($self)."::drop called directly");
  }
}

sub open {
  my $self = shift;
  my $file = $self->{file};

  if (exists $self->{dbh}) {
    $self->{dbh};
  } else {
    $self->{dbh} = tie(%{$self->{db}}, 'DB_File', $file,
                       $self->{mode}, 0664, $DB_BTREE);
  }
}

sub insert {
  my $self  = shift;
  my $key   = shift;
  my %parm  = @_;

  defined $self->{db} or $self->open;

  my $tuple = join($;, map($parm{$_}, @{$self->{attr}}));

  if (exists $self->{db}->{$tuple}) {
    # duplicate entry
    return undef;
  }
  $self->{db}->{$tuple} = $key;
}

sub have {
  my $self  = shift;
  my %parm  = @_;

  defined $self->{db} or $self->open;

  my $tuple = join($;, map($parm{$_}, @{$self->{attr}}));

  exists $self->{db}->{$tuple} && $self->{db}->{$tuple};
}

sub fetch {
  my $self  = shift;
  my %parm  = @_;
  my @keys  = @{$self->{attr}->[0]};

  defined $self->{db} or $self->open;

  my $key   = join($;, map($parm{$_}, @keys));
  $self->{db}->{$key};
}

sub delete {
  my $self  = shift;
  my $key   = shift;
  my %parm  = @_;

  defined $self->{db} or $self->open;

  my $tuple = join($;, map($parm{$_}||"", @{$self->{attr}}));

  delete $self->{db}->{$tuple};
}

sub sync {
  my $self = shift;
  $self->{dbh}->sync if $self->{dbh};
}

sub close {
  my $self = shift;

  delete $self->{scans} if defined $self->{scans};

  if ($self->{dbh}) {
    delete $self->{dbh};
    untie %{$self->{db}};
    delete $self->{db};
  }
}

#sub DESTROY { $_[0]->close }

sub open_scan {
  my $self = shift;
  my $code = shift;

  $self->{dbh} or $self->open;
  new WAIT::IndexScan $self, $code;
}

1;
