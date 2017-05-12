# Copyright 2008, 2009, 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

package App::MathImage::Gtk1::Ex::SignalIds;
use 5.004;
use strict;
use Carp;
use Scalar::Util;

use vars '$VERSION','@ISA';
$VERSION = 110;

# uncomment this to run the ### lines
#use Devel::Comments;

sub new {
  my ($class, $object, @ids) = @_;

  # it's easy to forget the object in the call (and pass only the IDs), so
  # validate the first arg now
  (Scalar::Util::blessed($object) && $object->isa('Gtk::Object'))
    or croak 'Gtk::Ex::SignalIds->new(): first param must be the target object';

  my $self = bless [ $object ], $class;
  Scalar::Util::weaken ($self->[0]);
  $self->add (@ids);
  return $self;
}
sub add {
  my ($self, @ids) = @_;
  push @$self, @ids; # grep {$_} @ids;
}

sub DESTROY {
  my ($self) = @_;
  $self->disconnect;
}

sub object {
  my ($self) = @_;
  return $self->[0];
}
sub ids {
  my ($self) = @_;
  return @{$self}[1..$#$self];
}

sub disconnect {
  my ($self) = @_;

  my $object = $self->[0];
  if (! $object) { return; }  # target object already destroyed

  while (@$self > 1) {
    my $id = pop @$self;

    # might have been disconnected by $object in the course of its destruction
    if ($object->signal_handler_is_connected ($id)) {
      $object->signal_handler_disconnect ($id);
    }
  }
}

1;
__END__
