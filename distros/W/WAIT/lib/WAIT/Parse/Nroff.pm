#                              -*- Mode: Cperl -*- 
# Nroff.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Sep 16 15:54:25 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:41 1998
# Language        : CPerl
# Update Count    : 160
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Parse::Nroff;
require WAIT::Parse::Base;
use vars qw(@ISA %GOOD_HEADER $DEFAULT_HEADER);
@ISA = qw(WAIT::Parse::Base);

%GOOD_HEADER = (
                name         => 1,
                synopsis     => 1,
                options      => 1,
                description  => 1,
                author       => 1,
                example      => 1,
                bugs         => 1,
                text         => 1,
                see          => 1,
                environment  => 1,
               );
my $HEADER_REGEXP = uc join '|', keys %GOOD_HEADER;
$DEFAULT_HEADER = 'text';

sub split {                     # called as method
  my %result;
  my $fld    = $DEFAULT_HEADER;    # do not drop any words
  my $indent = 8;
  # initialize to make perl -w happy
  @result{keys %GOOD_HEADER} = ('') x scalar(keys %GOOD_HEADER);
  
  $_[1] =~ s/-\s*\n\s*//g;
  $_[1] =~ s/.//g;
  for (split /\n/, $_[1]) {
    if (s/^(\s*)($HEADER_REGEXP)\b//o) {
      my $id = length($1);
      if ($id <= $indent) {
        $fld = lc($2);
        if ($id < $indent) {
          # Some weired systems (IRIX) have a left margin here!
          # so let's adapt to the smallest one
          $indent = $id;
        }
      }
    }

    $result{$fld} .= $_ . ' ';
  }
  #print STDERR "\n";
  return \%result;              # we go for speed
}

sub tag {                       # called as method
  my @result;
  my $tag  = $DEFAULT_HEADER;   # do not drop any words
  my $text = '';
  my $line = 0;

  for (split /\n/, $_[1]) {
    $line++;
    $line -= 66 if $line > 66;
    next if $line <  5;
    next if $line >  62;
    next if $line <  8   and /^\s*$/;
    next if $line >  59  and /^\s*$/;
    if (s/^((([A-Z])(\3)+){3,})//) {
      my $header = WAIT::Filter::unroff($1);
      push @result, _tag($text, $tag);
      $text = '';
      push @result, {_b => 1}, $header;
      $header = lc $header;
      $tag = ($GOOD_HEADER{$header}?$header:$DEFAULT_HEADER);
    }
    $text .= "$_\n";
  }
  push @result, _tag($text, $tag);
  return @result;               # we don't go for speed
}

sub _tag {
  local($_) = shift;
  my $tag   = shift;

  return unless defined $tag;
  #print STDERR "$tag-";
  my @result;
  my ($b, $i, $n);
  if (defined $tag) {
    $b = {$tag => 1, _b => 1};
    $i = {$tag => 1, _i => 1};
    $n = {$tag => 1};
  } else {
    $b = {_b => 1};
    $i = {_i => 1};
    $n = {};
  }
  while (length($_)) {
    if (s/^(((.)(\3)+)+\s*)//o) {
      push @result, $b, WAIT::Filter::unroff($1);
    } elsif (s/^((_.)+)//o) {
      push @result, $i, WAIT::Filter::unroff($1);
    } elsif (s/^([^]+)(.)/$2/o) {
      push @result, $n, $1;
    } else {
      s/.//g;
      push @result, $n, $_;
      $_ = '';
    }
  }
  #print STDERR '+';
  @result;
}


package WAIT::Filter;

sub unroff {
  my $text = shift;
  $text =~ s/.//g;
  $text;
}

1;
__END__
sub bold {
  join '', map "$_($_)+", grep /./, split /(.)/, $_[0];
}

