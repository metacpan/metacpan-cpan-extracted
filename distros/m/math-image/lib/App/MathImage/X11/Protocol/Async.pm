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


package App::MathImage::X11::Protocol::Async;
use 5.004;
use strict;
use Carp;

use vars '$VERSION';
$VERSION = 110;

# X11::Protocol

sub send {
  my ($class, $X, $request, @args) = @_;
  my $seq = $X->send ($request, @args);
  my %self = (X       => $X,
              request => $request,
              seq     => $seq,
              data    => undef);
  $X->add_reply ($seq, \($self{'data'}));
  return bless \%self, $class;
}

sub receive {
  my ($self) = @_;
  my $X = $self->{'X'};
  $X->handle_input_for ($self->{'seq'});
  $X->delete_reply (delete $self->{'seq'});
  if (! defined $self->{'data'}) {
    croak "Error";
  }
  return $X->unpack_reply ($self->{'request'}, $self->{'data'});
}

sub DESTROY {
  my ($self) = @_;
  # FIXME: this cleans up, but provokes a carp() if the reply arrives
  if ((my $X = $self->{'X'})
      && (my $seq = delete $self->{'seq'})) {
    $X->delete_reply ($seq);
  }

  # this assumes the $X is still connected
  # if ((my $X = $self->{'X'})
  #     && (my $seq = delete $self->{'seq'})) {
  #   $X->handle_input_for ($self->{'seq'});
  #   $X->delete_reply (delete $self->{'seq'});
  # }
}

1;
__END__
