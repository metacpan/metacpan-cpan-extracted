# Copyright 2010 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

package App::RSS2Leafnode::Localize::GetSetMethod;
use strict;
use warnings;

sub new {
  my ($class, $target, $method, $value) = @_;
  my $self = bless { subr   => $subr,
                     target => $target,
                     method => $method,
                     old    => $target->$method }, $class;
  if (@_ >= 4) {
    $self->set($value);
  }
  return $self;
}

sub DESTROY {
  my ($self) = @_;
  $self->set($self->{'old'});
}

sub set {
  my ($self, $value) = @_;
  my $target    = $self->{'target'};
  my $method = $self->{'method'};
  $target->$method($value);
}

1;
__END__
