#                              -*- Mode: Cperl -*- 
# Split.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Sun Sep 15 14:42:09 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:47 1998
# Language        : CPerl
# Update Count    : 66
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Document::Split;
@ISA = qw(WAIT::Document::Base);
require WAIT::Document::Base;

use FileHandle;
use strict;
#use diagnostics;
use Carp;

sub TIEHASH {
  my $type   = shift;
  my $mode   = shift;
  my $regexp = shift;
  my @files  = grep -f $_, @_;

  my $self   = {Regexp => $regexp,
                Mode   => $mode,
                Files  => \@files};
  bless $self, ref($type) || $type;
}

sub FETCH {
  my $self = shift;
  my $key  = shift;

  # cached ?
  if (defined $self->{Key} and $self->{Key} eq $key) {
    return $self->{Value};
  }
  my ($file, $start, $length) = split ' ', $key;
  unless (defined $self->{File} and $self->{File} eq $file) {
    $self->openfile($file) or return;
  }
  #$fh->seek($start, 0); #SEEK_SET);
  $self->seek($start);
  $self->{Key}   = $key;
  $self->{Value} = '';
  $length = $self->{Fh}->read($self->{Value}, $length);
  $self->{_pos} += $length;
  $self->{Value};
}

# Emulate seek on gziped files.
sub seek {
  my $self = shift;
  my $pos  = shift;

  if ($self->{File} =~ /\.gz$/) {
    my $buf = '';
    if ($self->{_pos} < $pos) {
      $self->{Fh}->read($buf,$pos - $self->{_pos});
      $self->{_pos} = $pos;
    } elsif ($self->{_pos} > $pos) {
      my $file = $self->{File};
      $self->closefile;
      $self->openfile($file);
      $self->{Fh}->read($buf,$pos);
      $self->{_pos} = $pos;
    } else {
      1;
    }
  } else {
    $self->{Fh}->seek($pos, 0); #SEEK_SET);
  }
  
}

sub FIRSTKEY {
  my $self = shift;


  $self->{have} = [@{$self->{Files}}];
  return undef unless $self->nextfile();
  $self->NEXTKEY;
}

sub isopen {
  my $self = shift;

  exists $self->{Fh};
}

sub closefile {
  my $self = shift;

  if ($self->{Line}) {
    delete $self->{Line};
  }
  if ($self->{Fh}) {
    $self->{Fh}->close;
    delete $self->{Fh};
    delete $self->{File};
    $self->{_pos} = 0;
  }
}

sub openfile {
  my $self = shift;
  my $file = shift;
  my $fh;

  $self->closefile;

  if ($file =~ /\.gz$/) {
    $fh = new FileHandle "gzip -cd $file|";
  } else {
    $fh = new FileHandle "< $file";
  }

  unless (defined $fh) {
    return undef;
  }
  $self->{_pos} = 0;
  $self->{File} = $file;
  $self->{Fh}   = $fh;
}

sub close {
  my $self = shift;

  $self->closefile;
  for (qw(have Key Value File)) {
    delete $self->{$_} if exists $self->{$_};
  }
}

sub nextfile {
  my $self = shift;
  my $file = shift @{$self->{have}};

  return undef unless defined $file;
  $self->openfile($file);
}

sub NEXTKEY {
  my $self = shift;
  my $line;
  my $match;
  
  $self->isopen || $self->nextfile || return(undef);

  my $start = $self->{Fh}->tell;
  if (defined $self->{Line}) {
    $start -= length($self->{Line});
    $self->{Value} = $self->{Line};
  } else {
    $self->{Value} = '';
  }

  my $fh = $self->{Fh};
  while (defined($line = <$fh>)) {
    if ($line =~ /$self->{Regexp}/) {
      $match = 1;
      if ($self->{Mode} =~ /end/i) {
        $self->{Value} .= $line;
      } elsif ($self->{Mode} =~ /start/i) {
        $self->{Line}   = $line;
      }
      last;
    }
    $self->{Value} .= $line;
  }
  my $length = length($self->{Value});
  $self->{Key} = "$self->{File} $start $length";
  unless ($match) {             # EOF
    $self->closefile;
  }
  $self->{Key};
}

1;
