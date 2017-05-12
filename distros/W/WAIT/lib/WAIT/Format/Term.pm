#                              -*- Mode: Perl -*- 
# Term.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Wed Sep 18 20:10:42 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Nov 22 18:44:44 1998
# Language        : CPerl
# Update Count    : 15
# Status          : Unknown, Use with caution!
# 
# Copyright (c) 1996-1997, Ulrich Pfeifer
# 

package WAIT::Format::Term;
require WAIT::Format::Base;
use strict;
use vars qw(@ISA);
require Term::Cap;
my %DEFAULT;
@ISA = qw(WAIT::Format::Base);

my $terminal = eval {Tgetent Term::Cap { TERM => undef, OSPEED => 9200 }};
unless (defined $terminal) {
  eval { require Term::Info; };
  if ($@ ne '') {
    warn "Neither Term::Cap nor Term::Info seems to work.".
         " Reverting to dumb settings";
    %DEFAULT = (
                bold_s   => '*',
                bold_e   => '*',
                query_s  => '[',
                query_e  => ']',
                italic_s => '_',
                italic_e => '_',
               );
  } else {
    import Term::Info qw(Tput);
    %DEFAULT = (
               bold_s   => Tput("bold"),
               bold_e   => Tput("sgr0"),
               query_s  => Tput("rev"),
               query_e  => Tput("sgr0"),
               italic_s => Tput("smul"),
               italic_e => Tput("sgr0"),
              );
  }
} else {
  %DEFAULT = (
               bold_s   => $terminal->{_md},
               bold_e   => $terminal->{_me},
               query_s  => $terminal->{_mr} || $terminal->{_md},
               query_e  => $terminal->{_me},
               italic_s => $terminal->{_us},
               italic_e => $terminal->{_ue},
              );
}

sub new {
  my $type = shift;
  my %parm = @_;
  my %self = %DEFAULT;
  
  for (keys %DEFAULT) {
    $self{$_} = $parm{$_} if exists $parm{$_};
  }
  bless \%self, ref($type) || $type;
}

sub bold {
  my $self = shift;
  $self->{bold_s} . $_[0] . $self->{bold_e};
}

sub italic {
  my $self = shift;
  $self->{italic_s} . $_[0] . $self->{italic_e};
}

sub query {
  my $self = shift;
  $self->{query_s} . $_[0] . $self->{query_e};
}

1;
