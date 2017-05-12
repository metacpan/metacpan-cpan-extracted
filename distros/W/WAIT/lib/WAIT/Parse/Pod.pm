#                              -*- Mode: Perl -*- 
# WAIT::Parse::Pod -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Sat Dec 14 17:38:29 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:40 1998
# Language        : CPerl
# Update Count    : 275
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 
package WAIT::Parse::Pod;
use Pod::Parser;
use Carp;
use vars qw(@ISA %GOOD_HEADER);

# Got tired reinstalling Pod::Parser after each perl rebuild. So I renamed
# Pod::Text to Pod::PText. Thus this hack:
BEGIN {
  eval {require Pod::PText;};
  if ($@ ne '') {
    require Pod::Text;
    croak "Need Pod::Tex version > 2.0" if $Pod::Text::VERSION < 2.0;
    @ISA = qw(Pod::Text Pod::Parser WAIT::Parse::Base);
  } else {
    @ISA = qw(Pod::PText Pod::Parser WAIT::Parse::Base);
  }
}
use Text::Tabs qw(expand);
use strict;



# recognized =head1 headers
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

sub default_indent () {4};

# make frequent tag sets reusable
my $CODE   = {text => 1, _c => 1};
my $BOLD   = {text => 1, _b => 1};
my $ITALIC = {text => 1, _i => 1};
my $PLAIN  = {text => 1};

sub new {
  my $this  = shift;
  my $class = ref($this) || $this;
  my $self  = $this->SUPER::new(@_);
  bless $self, $class;
}

sub begin_input {
  my $self = shift;
  
  $self->indent(default_indent);
  $self->{TAGS} = {};
  $self->{OUT}  = [];
}

sub indent {
  my $self = shift;

  if (@_) {
    $self->{INDENT} = shift;
  }
  $self->{INDENT};
}

# Stolen afrom Pod::Parser by Tom Christiansen and Brad Appleton and modified
sub interpolate {
  my $self = shift;
  my ($text, $end_re) = @_;

  $text   = ''    unless (defined $text);
  $end_re = "\$"  unless ((defined $end_re) && ($end_re ne ''));
  local($_)  = $text;
  my @result;

  my ($seq_cmd, $seq_arg, $end) = ('', '', undef);
  while (($_ ne '') && /([A-Z])<|($end_re)/) {
    # Only text after the match remains to be processed
    $_ = $';
    # Append text before the match to the result
    push @result, $self->{TAGS}, $`;
    # See if we matched an interior sequence or an end-expression
    ($seq_cmd, $end) = ($1, $2);
    last if (defined $end);  # Saw the end - quit loop here
    # At this point we have found an interior sequence,
    # we need to obtain its argument
    if ($seq_cmd =~ /^([FBIC])/) {
      my $tag = '_' . lc $1;
      my $tags = $self->{TAGS};
      my %tags = (%{$tags}, $tag => 1);
      $self->{TAGS} = \%tags;
      push @result, $self->interpolate($_, '>');
      $self->{TAGS} = $tags;
    } else {
      my @seq_arg = $self->interpolate($_, '>');
      my $i;
      
      for ($i=1;$i<=@seq_arg;$i+=2) {
        push @result, $seq_arg[$i-1],
        $self->interior_sequence($seq_cmd, $seq_arg[$i]);
      }
    }
  }
  ## Handle whatever is left if we didnt match the ending regexp
  unless ((defined $end) && ($end_re ne "\$")) {
    push @result, $self->{TAGS}, $_;
    $_ = '';
  }
  ## Modify the input parameter to consume the text that was
  ## processed so far.
  $_[0] = $_;
  ## Return the processed-text
  return  @result;
}

sub textblock {
  my ($self, $text) = @_;

  $self->output($self->interpolate($self->wrap($text)), $PLAIN, "\n\n");
}

sub output {
  my ($self) = shift;

  while (@_) {
    my $tags = shift;
    my $text = shift;
    croak "Bad tags parameter: '$tags'" unless ref($tags);
    push @{$self->{OUT}},  $tags, $text;
  }
}

sub verbatim  {
  my ($self, $text) = @_;
  my $indent = $self->indent() + default_indent;

  $text = expand($text);
  my ($prefix) = ($text =~ /^(\s+)/);

  if (length($prefix) < $indent) {
    my $add = ' ' x ($indent - length($prefix));
    $text =~ s/^/$add/gm;
  } elsif (length($prefix) > $indent) {
    my $sub = ' ' x (length($prefix) - $indent);
    $text =~ s/^$sub//gm;
  }
  $self->output($CODE, $text);
}

sub command {
  my ($self, $cmd, $arg, $sep) = @_;

  if ($cmd =~ /^head(\d)/) {
    my $indent = $1-1;
    my $tags   = $self->{TAGS};

    $self->{TAGS} = $BOLD;
    $self->output($self->interpolate($self->wrap($arg,
                                         $indent*default_indent)."\n\n"));
    if ($indent) {
      $self->{TAGS} = $tags;
    } else {
      my $sarg = lc $arg;
      $sarg =~ s/\s.*//g;
      if ($GOOD_HEADER{$sarg}) {
        $self->{TAGS} = {lc $sarg => 1}
      } else {
        $self->{TAGS} = {text => 1}
      }
    }
  } elsif ($cmd =~ /^back/) {
    $self->indent(default_indent);
  } elsif ($cmd =~ /^over/) {
    my $indent = (($arg)?$arg:default_indent) + default_indent;
    $self->indent($indent);
  } elsif ($cmd =~ /^item/) {
    $self->output($self->interpolate($self->wrap($arg,default_indent)."\n\n"))
  } else {
    $self->output($self->{TAGS}, $arg);
  }
}

# inspired from Text::Wrap by David Muir Sharnoff
sub wrap {
  my ($self, $t, $indent) = @_;
  $indent = $self->indent unless defined $indent;
  
  my $columns      = 76 - $indent;
  my $ll           = $columns;
  my $prefix       = ' ' x $indent;
  my $result       = $prefix;
  my $length;

  # E/L will probably change length 
  $t =~ s/([EL])<(.*?)>/$self->interior_sequence($1,$2)/eg;
  $t =~ s/\s+/ /g;
  while ($t =~ s/^(\S+)\s?//o) {
    my $word = $1;

    # inline length calculation for speed
    my $dummy = $word;
    $dummy =~ s/[A-Z]<(.*?)>/$1/og;
    $length = length($dummy);

    if ($length < $ll) {
      $result .= $word . ' ';
      $ll     -= $length + 1;
    } else {
      $result  =~ s/ $/\n/;
      $result .= $prefix . $word . ' ';
      $ll = $columns - $length - 1;
    }
  }
  return $result;
}


sub parse_from_string {
  my $self         = shift;
  local($_);
  
  $self->{CUTTING}   = 1;       ## Keep track of when we are cutting
  $self->begin_input();
  
  my $paragraph = '';
  for (split /\n\s*\n/, $_[0]) {
    $self->parse_paragraph($_ . "\n\n");
  }
  
  $self->end_input();
}


sub tag {
  my $self         = shift;

  $self->begin_input;
  $self->parse_from_string(@_);
  my $result = $self->{OUT};
  delete $self->{OUT};
  delete $self->{TAGS};
  @{$result};
}
