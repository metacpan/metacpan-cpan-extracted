#                              -*- Mode: Cperl -*- 
# Query.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Fri Sep 13 13:05:52 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Fri Apr 14 16:27:01 2000
# Language        : CPerl
# Update Count    : 57
# Status          : Unknown, Use with caution!
#
# Copyright (c) 1996-1997, Ulrich Pfeifer
#

package WAIT::Query::Base;

sub new {
  my $type  = shift;
  my $table = shift;
  my $self  = {Table => $table};

  bless $self, ref($type) || $type;
  if (@_) {
    $self->add(@_);
  } else {
    $self;
  }
}

sub add {
  my ($self, $fldorref, %parm) = @_;
  my @fld = (ref $fldorref)?@$fldorref:$fldorref;
  my $fld;

  for $fld (@fld) {
    if (defined $parm{Plain}) {
      if (defined $self->{Plain}->{$fld}) {
        $self->{Plain}->{$fld} .= ' ' . $parm{Plain};
      } else {
        $self->{Plain}->{$fld}  =       $parm{Plain};
      }
    }
    if (defined $parm{Raw}) {
      if (defined $self->{Raw}->{$fld}) {
        $self->{Raw}->{$fld}->merge($parm{Raw});
      } else {
        $self->{Raw}->{$fld} =      $parm{Raw};
      }
    }
  }
  $self;
}

sub merge {
  my ($self, $other) = @_;
  my $fld;

  if (ref($self) ne ref($other)) {
    return $other->merge($self);
  }
  for $fld (keys %{$other->{Plain}}) {
    $self->add($fld, Plain => $other->{Plain}->{$fld});
  }
  for $fld (keys %{$other->{Raw}}) {
    $self->add($fld, Raw => $other->{Raw}->{$fld});
  }

  $self;
}

sub clone {
  my $self = shift;
  my %copy;
  my $fld;

  for $fld (keys %{$self->{Plain}}) {
    $copy{Plain}->{$fld} = $self->{Plain}->{$fld};
  }
  for $fld (keys %{$self->{Raw}}) {
    next unless defined $self->{Raw}->{$fld}; # XXX bug elsewere
    $copy{Raw}->{$fld} = $self->{Raw}->{$fld}->clone;
  }

  $self;
}

sub execute {
  my $self = shift;
  my $tb   = $self->{Table};
  my %result;
  my $fld;

  for $fld (keys %{$self->{Plain}}, keys %{$self->{Raw}}) {
    %r = $tb->search(
                     { attr => $fld,
                       cont => $self->{Plain}->{$fld},
                       raw  => $self->{Raw}->{$fld},
                       @_
                     }
                    );
    my ($key, $val);
    while (($key, $val) = each %r) {
      if (exists $result{$key}) {
        $result{$key} += $val;
      } else {
        $result{$key}  = $val;
      }
    }
  }
  %result;
}

sub hilight {
  my $self = shift;
  $self->{Table}->hilight($_[0], $self->{Plain}, $self->{Raw})
}

sub flatten {
  my $self = shift;
  #print STDERR "WAIT::Query::Base::flatten($self)\n";
  $self->clone()
}

package WAIT::Query::bin;

sub new {
  my $type = shift;
  my $self = [@_];

  #print STDERR "WAIT::Query::bin::new $type $self\n";
  bless $self, ref($type) || $type;
}

sub flatten {
  my $self = shift;
  #print STDERR "WAIT::Query::bin::flatten($self)\n";
  $self->[0]->flatten->merge($self->[1]->flatten)
}

sub hilight {
  my $self  = shift;
  my $query = $self->flatten();

  $query->hilight(@_);
}

package WAIT::Query::and;

@ISA = qw(WAIT::Query::bin);

sub execute {
  my $self = shift;
  my %ra = $self->[0]->execute();
  my %rb = $self->[1]->execute();

  #print STDERR "WAIT::Query::and::execute\n";
  for (keys %ra) {
    if (exists $rb{$_}) {
      $ra{$_} *= $rb{$_};
      delete $ra{$_} if $ra{$_} <= 0;
    } else {
      delete $ra{$_};
    }
  }
  %ra;
}


sub merge {
  #print STDERR "WAIT::Query::and::merge(@_)\n";
  new WAIT::Query::or @_;        # XXX
}

package WAIT::Query::or;

@ISA = qw(WAIT::Query::bin);

sub execute {
  my $self = shift;
  my %ra = $self->[0]->execute();
  my %rb = $self->[1]->execute();

  for (keys %ra) {
    if (exists $rb{$_}) {
      $ra{$_} += $rb{$_}
    }
  }
  for (keys %rb) {
    unless (exists $ra{$_}) {
      $ra{$_} = $rb{$_}
    }
  }
  %ra;
}


sub merge {
  my $self = shift;

  if (ref($_[0]) eq 'WAIT::Query::Base') {
    $self->[0] = $self->[0]->merge($_[0]);
  } else {
    new WAIT::Query::or $self, @_;        # XXX
  }
}

package WAIT::Query::not;

@ISA = qw(WAIT::Query::and WAIT::Query::bin);

sub execute {
  my $self = shift;
  my %ra = $self->[0]->execute();
  my %rb = $self->[1]->execute();

  for (keys %ra) {
    if (exists $rb{$_}) {
      if (exists $ra{$_}) {
        $ra{$_} -= $rb{$_};
        delete $ra{$_} if $ra{$_} <= 0;
      }
    }
  }

  %ra;
}

package WAIT::Query::Raw;
use strict;
use Carp;

sub new {
  my $type = shift;
  my $self = shift;

  $self = {} unless defined $self;
  bless $self, ref($type) || $type;
}

sub clone {
  my $self = shift;
  my %copy;

  for (keys %$self) {
    $copy{$_} = [@{$self->{$_}}];
  }
  $self->new(\%copy);
}

# Modifies first argument
sub merge {
  my $self  = shift;
  my $other = shift;

  croak "$other is not at 'WAIT::Query'" unless ref($other) =~ /^WAIT::Query/;
  for (keys %$other) {
    if (exists $self->{$_}) {
      push @{$self->{$_}}, @{$other->{$_}}
    } else {
      $self->{$_} = $other->{$_};
    }
  }
}

1;
