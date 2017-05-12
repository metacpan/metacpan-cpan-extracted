#!/usr/local/ls6/bin/perl
#                              -*- Mode: Perl -*- 
# Dict.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Feb 26 18:34:50 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Fri Feb 14 16:08:43 1997
# Language        : Perl
# Update Count    : 110
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1996, Universität Dortmund, all rights reserved.
# 

package Wais::Dict;
use Carp;
use FileHandle;

# Return the moral equivalen of ($x-$y)
#  0 $x == $y
# -1 $x < $y
#  1 $x > $y
sub cmp {
  my ($cx, $cy) = @_;
  
  # $x is empty. If $y is not empty, it is larger
  return (length($cy))?-1:0 unless defined $cy and length($cx);
  
  # $x is not empty, $y is empty
  return 1 unless defined $cy and length($cy);
  
  (ord($cx) <=> ord($cy))       # test the  first character
    || 
      &cmp(substr($cx,1), substr($cy,1)); 
}


sub whowasi { (caller(1))[3] . '()' }

sub TIEHASH {
    my $type = shift;
    my $self = {};
    my $file = shift;

    $self->{FN} = $file;
    $file = "$file.dct";

    croak "usage: @{[&whowasi]} FILE" if @_;
    croak "usage: @{[&whowasi]} FILE" unless -e $file;
    my $fh = new FileHandle;
    unless ($fh->open("< $file")) {
        croak "Could not open $file: $!";
    }
    my $buf = '';
    read($$fh,$buf,4) || croak "Could not read header: $!";
    my ($magic, $blk) = unpack 'Sn', $buf;
    croak "$file is no dictionary file" if $magic != 0;
    # older versions of freewais-sf seem to have wrong blk??
    # we use the file size to compute blk.
    my $sblk = (((-s $file)-2)/29);
    $blk = $sblk % 1000 if $sblk = int($sblk);
    
    my (%dir, @dir);
    $self->{FI} = 4+29*$blk;
    while ($blk-->0) {
        read($$fh,$buf,29);
        my ($term,$ptr, $occ) = unpack 'A21 N N', $buf;
        last unless $term;
        push @dir, $term;
        $dir{$term} = $ptr;
    }
    $self->{FH} = $fh;
    $self->{DA} = \@dir;
    $self->{DH} = \%dir;
    bless $self, $type;
}

sub FETCH {
    my $self   = shift;
    my $term   = shift;
    my $op     = shift;
    my $result;

    if (defined $self->{KEY} and $self->{KEY} eq $term) {
        $result = $self->{VALUE};
        return (($op)?$result->[0]:$result->[1]);
    } else {
        my ($blk, $ble) = (0,0);
        # try the first entries  of each block
        for (@{$self->{DA}}) {
            if (&cmp($_,$term) != 1) { # $_ le $term:
              # $term must be in this block or after
              $blk = $_;
            } elsif (&cmp($_ ,$term) == 1) { # $_ gt $term
              # $term must be before this block
              $ble = $_;
              last;
            }
        }
        my $sst = $self->{DH}->{$blk} || $self->{FI};
        my $sse = $self->{DH}->{$ble} || $sst + 29000;
        my $fh  = $self->{FH};
        $result = &binsearch($fh,$sst,$sse,$term);
        if ($result) {
            return (($op)?$result->[0]:$result->[1]);
        } else {
            return $result;
        }
    }
}

sub binsearch {
    my ($fh,$left,$right,$term) = @_;
    my ($fterm,$ptr, $occ);

    if ($left + 29 > $right) {  # intervall collapsed
        ($fterm,$ptr, $occ) = &getterm($fh, $left);
        if (defined $fterm and $term eq $fterm) {  # hit
            return [$ptr, $occ] ;
        } else {
          my $cmp = &cmp($term, $fterm);
          $fh->seek(-29,1) if $cmp < 0;
          return undef;       # no found
        }
    } else {                    # partition intervall
        my $mid = $left + int(($right-$left)/2/29)*29;
        ($fterm,$ptr, $occ) = &getterm($fh, $mid);
        my $cmp;
        unless (defined $fterm and length($fterm)) {
            $cmp = -1;          # $fterm after end of dictionary
        } else {
            $cmp = &cmp($term, $fterm);
        }
        if ($cmp == -1) {       # $term is left of $fterm
            &binsearch($fh,$left,$mid-29,$term);
        } elsif ($cmp == 1) {   # must be in the right intervall
            &binsearch($fh,$mid+29,$right,$term);
        } else {
            [$ptr, $occ];
        }
    }
}

# get the term at $offset => (term, pointer, occurance)
sub getterm {
    my ($fh,$offset) = @_;

    $fh->seek($offset,0) or return undef;
    my $buf = '';               # perl -w
    read($$fh,$buf,29)==29 or return undef;
    unpack 'A21 N N', $buf;
}

sub FIRSTKEY {
    my $self = shift;
    my $fh   = $self->{FH};

    $fh->seek($self->{FI}, 0) || croak "Seek failed: $!";
    $self->NEXTKEY;
}

sub NEXTKEY {
    my $self = shift;
    my $buf  = '';
    my $fh   = $self->{FH};

    read($$fh,$buf,29) || return undef;
    my ($term,$ptr, $occ) = unpack 'A21 N N', $buf;

    return undef unless $term;  # just paranoid
    # We save the value for this term since each() calls NEXTKEY/FETCH
    # each might get (key,value) with one function call better?
    $self->{KEY}   = $term;
    $self->{VALUE} = [$ptr, $occ];
    return $term;
}

sub PREVKEY {
    my $self = shift;
    my $buf  = '';
    my $fh   = $self->{FH};

    $self->{FH}->seek(-29,1)         || return undef;
    $self->{FH}->tell >= $self->{FI} || return undef;
    read($$fh,$buf,29)               || return undef;
    $self->{FH}->seek(-29,1)         || return undef;

    my ($term,$ptr, $occ) = unpack 'A21 N N', $buf;

    return undef unless $term;  # just paranoid
    # We save the value for this term for no particular reason.
    $self->{KEY}   = $term;
    $self->{VALUE} = [$ptr, $occ];
    return $term;
}

sub CURRENT {                   # should not be used
    shift->{VALUE};
}

sub DESTROY {                   # close open files
    my $self = shift;
    if (defined $self->{FH}) {
        $self->{FH}->close;
        delete $self->{FH};
    }
    if (defined $self->{INV}) {
        $self->{INV}->close;
        delete $self->{INV};
    }
}

# Set file position to first term having $term as prefix but does not
# really do that :-( This is nearly the same than FETCHing the
# term. If the term is present in the dictionary, we move the cursor
# one entry back so that NEXTKEY will find it. If we did not find the
# key, where will FETCH happen to leave the cursor? Hopefully after
# the position where the word would have been if it were in the
# dictionary.

sub SET {
    my $self = shift;
    my $term = shift;
    my $found; 

    $found = $self->FETCH($term);
    if ($found) {    # wanna see that again!
        $self->{FH}->seek(-29,1);
    }
    1;
}

# Get the posting list of $term
sub POSTINGS {
  my $self   = shift;
  my $term   = shift;
  my $fh     = $self->{INV};
  my $offset = $self->FETCH($term,1);
  my @result;
  
  return unless $offset;        # just paranoid
  unless ($fh) {
    $self->{INV} = $fh = new FileHandle;
    unless ($fh->open("< " . $self->{FN}.'.inv')) {
      croak "Could not open $self->{FN}.inv: $!";
    }
  }
  $fh->seek($offset,0) || confess "could not seek: $!\n";

  my ($flag,$npo,$size,$did,$bsize,$weight,$ch,$cl,$charpos);
  my $buf = '';
  read($$fh,$buf,9);
  ($flag,$npo,$size) = unpack 'aNN', $buf;
  return unless $size;
  for (1 .. $npo) {
    my @pos;
    read($$fh,$buf,15);
    ($did,$bsize,$weight,$ch,$cl) = unpack 'NIfnC*', $buf;
    $charpos = ($ch<<8) + $cl;
    if ($bsize>3) {
      read($$fh,$buf,$bsize-3);
      if ($COMPRESS_PATCH_AVAIL) {
        @pos = unpack 'w*', $buf; # compressed in patch needed
      } else {
        # use this for unpatched perl
        while(length($buf)) {
          push(@pos, &readCompressedInteger(*buf));
        }
      }
    }
    # result should be fed to a hash
    push @result, $did, [$weight, $charpos, @pos];
  }
  @result;
}

{ my $x;
  eval {$x = pack 'w', 1};
  if ($x eq "\001") {
    $COMPRESS_PATCH_AVAIL = 1;
  }
}

# should be autoloaded. 
sub readCompressedInteger {
  local (*buf) = @_;
  my ($number, $byte);
  
  # this initialisation is just for tuning: most frequent case is
  # 0<=n<=127
  ($byte, $buf) = unpack("C1 a*", $buf);
  return($byte) if (($byte & 128)==0);
  $number = $byte&127;
  
  do {                          # get one byte from buf at first
    ($byte, $buf) = unpack("C1 a*", $buf);
    $number <<= 7;
    $number += ($byte & 127);   # 127 = 7F in hexadecimal   
  } until (($byte & 128) == 0); # until the most significant  
  # bit of byte equals to 0
  $number;
}                        

1;
    
