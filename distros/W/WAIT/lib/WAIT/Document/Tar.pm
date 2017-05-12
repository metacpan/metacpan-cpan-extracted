#!/app/unido-i06/magic/perl
#                              -*- Mode: Perl -*- 
# Tar.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Sat Jan  4 12:34:52 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:47 1998
# Language        : CPerl
# Update Count    : 15
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Document::Tar;
@ISA = qw(WAIT::Document::Base);
require WAIT::Document::Base;

use FileHandle;
use strict;
use Carp;

my $DEBUG;

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

sub close_file {
  my $self = shift;

  if ($self->{_fh}) {
    delete $self->{_fh};        # implies close?
    delete $self->{_file};
  }
}


sub open_file {
  my $self = shift;
  my $file = shift;

  $self->close_file if $self->{_fh};

  unless (-f $file) {
    for (qw(.gz .Z)) {
      if (-f "$file$_") {
        $file .= $_;
        last;
      }
    }
  }
  return unless -f $file;

  if ($file =~ s/\.gz$//) {
    $self->{_fh}   = new IO::File "gzip -cd $file|";
  } elsif ($file =~ s/\.Z$//) {
    $self->{_fh}   = new IO::File "compress -cd $file|";
  } else {
    $self->{_fh}   = new IO::File "< $file";
  }
  $self->{_file} = $file;
  $self->{_fh};
}

sub next_file {
  my $self = shift;

  $self->close_file;
  return unless $self->{Pending} and @{$self->{Pending}};
  $self->open_file(shift  @{$self->{Pending}}) || $self->next_file;
}

# sub DESTROY {shift->close;}

sub FIRSTKEY {
  my $self = shift;
  $self->{Pending} = [@{$self->{Files}}];
  $self->NEXTKEY;
}

sub NEXTKEY {
  my $self = shift;

  $self->{_fh} or $self->next_file or return;
  my ($key, $val) = next_archive_file($self->{_fh});
  unless ($key) {               # tar archive completed
    $self->close_file;
    return $self->NEXTKEY;
  }
  return $self->NEXTKEY unless &{$self->{Pred}}($key);
  $self->{_val} = $val;
  $self->{_key} = $self->{_file} . $; . $key;
}

sub FETCH {
  my $self = shift;
  my $key  = shift;

  if ($key ne $self->{_key}) {
    # Random access; breaks keys, values, each
    my ($tar, $file) = split $;, $key;

    $self->close_file;          # We could read the rest of the
                                # current file first.
    $self->open_file($tar) or croak "Could not open '$tar': $!\n";
    while (1) {
      my ($tkey, $val) = next_archive_file($self->{_fh});
      unless ($tkey) {          # tar archive completed
        $self->close_file;
        return;
      }
      # Check the key, will not work at quiery time :-(
      # next unless &{$self->{Pred}}($tkey);
      $self->{_val} = $val;
      $self->{_key} = $self->{_file} . $; . $tkey;
      last if $key eq $self->{_key};
    }
  }
  $self->{_val};
}

sub close {
  my $self = shift;

  $self->close_file;
  delete $self->{Pending};
  delete $self->{Files};        # no need at query time
  delete $self->{_key};
  delete $self->{_val};
}

sub read_bytes {
  my ($fh, $bytes) = @_;
  my ($buf, $read) = ('', 0);   # perl -w IO/Handle.pm line 403 :-(

  if (($read = $fh->read($buf, $bytes)) != $bytes) {
    carp "Read $read instead of $bytes bytes";
  }
  $buf;
}

sub next_archive_file {
  my $fh  = shift;
  my $buf = read_bytes($fh, 512);
  
  my ($arch_name, $mode, $uid, $gid, $size, $mtime, $chksum,
      $linkflag, $arch_linkname , $magic, $uname, $gname, $devmajor,
      $devminor) =
        unpack 'a100 a8 a8 a8 a12 a12 a8 C a100 a8 a32 a32 a8 a8', $buf;
  print "
arch_name      = $arch_name
mode           = $mode
uid            = $uid
gid            = $gid
size           = $size
mtime          = $mtime
chksum         = $chksum
linkflag       = $linkflag
arch_linkname  = $arch_linkname 
magic          = $magic
uname          = $uname
gname          = $gname
devmajor       = $devmajor
devminor       = $devminor
" if $DEBUG;
  $size = oct $size;
  my $file = read_bytes($fh, $size);
  $size = $size % 512;
  read_bytes($fh, 512 - $size) if $size;
  $arch_name =~ s/\000.*//;
  return($arch_name, $file);
}

1;
