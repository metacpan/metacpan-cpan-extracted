package Tree::Interval::Node;
#
# Copyright (C) 2011 by Opera Software Australia Pty Ltd
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Derived from Tree::RedBlack by Benjamin Holzman <bholzman@earthlink.net>
# which bore this message:
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the Artistic License, a copy of which can be
#     found with perl.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     Artistic License for more details.
#
use strict;

sub new {
  my $type = shift;
  my $this = {};
  if (ref $type) {
    $this->{'parent'} = $type;
    $type = ref $type;
  }
  if (@_) {
    @$this{'low','high','val'} = @_;
  }
  return bless $this, $type;
}

sub DESTROY {
  if ($_[0]->{'left'}) { 
    (delete $_[0]->{'left'})->DESTROY;
  }
  if ($_[0]->{'right'}) {
    (delete $_[0]->{'right'})->DESTROY;
  }
  delete $_[0]->{'parent'};
}

sub low {
  my $this = shift;
  if (@_) {
    $this->{'low'} = shift;
  }
  $this->{'low'};
}

sub high {
  my $this = shift;
  if (@_) {
    $this->{'high'} = shift;
  }
  $this->{'high'};
}

sub val {
  my $this = shift;
  if (@_) {
    $this->{'val'} = shift;
  }
  $this->{'val'};
}

sub color {
  my $this = shift;
  if (@_) {
    $this->{'color'} = shift;
  }
  $this->{'color'};
}

sub left {
  my $this = shift;
  if (@_) {
    $this->{'left'} = shift;
  }
  $this->{'left'};
}

sub right {
  my $this = shift;
  if (@_) {
    $this->{'right'} = shift;
  }
  $this->{'right'};
}

sub parent {
  my $this = shift;
  if (@_) {
    $this->{'parent'} = shift;
  }
  $this->{'parent'};
}

sub successor {
  my $this = shift;
  if ($this->{'right'}) {
    return $this->{'right'}->min;
  }
  my $parent = $this->{'parent'};
  while ($parent && $this == $parent->{'right'}) {
    $this = $parent;
    $parent = $parent->{'parent'};
  }
  $parent;
}

sub min {
  my $this = shift;
  while ($this->{'left'}) {
    $this = $this->{'left'};
  }
  $this;
}

sub max {
  my $this = shift;
  while ($this->{'right'}) {
    $this = $this->{'right'};
  }
  $this;
}

1;
