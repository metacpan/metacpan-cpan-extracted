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


package App::MathImage::Wx::Params::Integer;
use 5.004;
use strict;
use POSIX ();
use Wx;
use Wx::Event;

use base 'Wx::SpinCtrl';
our $VERSION = 110;

# uncomment this to run the ### lines
#use Devel::Comments;


sub new {
  my ($class, $parent, $info) = @_;
  ### Params-Integer new(): "$parent", $info

  my $minimum = $info->{'minimum'};
  if (! defined $minimum) { $minimum = POSIX::INT_MIN(); }
  my $maximum = $info->{'maximum'};
  if (! defined $maximum) { $maximum = POSIX::INT_MAX(); }

  # my $display = ($info->{'display'} || $info->{'name'});
  my $self = $class->SUPER::new ($parent,
                                 Wx::wxID_ANY(),
                                 $info->{'default'}, # initial value
                                 Wx::wxDefaultPosition(),
                                 Wx::wxDefaultSize(),
                                 Wx::wxSP_ARROW_KEYS(),  # style
                                 $minimum,
                                 $maximum);

  if (defined (my $width = $info->{'width'})) {
    my ($digit_width) = $self->GetTextExtent('0123456789');
    $self->SetSize (int($digit_width/9 * ($width+2.5)),
                    -1);
  }

  Wx::Event::EVT_SPINCTRL ($self, $self, 'OnSpinChange');
  return $self;
}

sub OnSpinChange {
  my ($self) = @_;
  ### Params-Integer OnSpinChange() ...

  if (my $callback = $self->{'callback'}) {
    &$callback($self);
  }
}

1;
__END__
