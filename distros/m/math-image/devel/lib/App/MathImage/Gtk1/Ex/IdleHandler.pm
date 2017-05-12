# Copyright 2011, 2012, 2013 Kevin Ryde

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

package App::MathImage::Gtk1::Ex::IdleHandler;
use 5.004;
use strict;

# uncomment this to run the ### lines
#use Devel::Comments;

use vars '$VERSION';
$VERSION = 110;

sub new {
  my ($class, @ids) = @_;
  my $self = bless [], $class;
  $self->add (@ids);
  return $self;
}
sub add {
  my ($self, @ids) = @_;
  push @$self, @ids;
}

sub DESTROY {
  my ($self) = @_;
  $self->remove;
}

sub remove {
  my ($self) = @_;
  while (my $id = pop @$self) {
    Gtk->idle_remove ($id);
  }
}

1;
__END__
