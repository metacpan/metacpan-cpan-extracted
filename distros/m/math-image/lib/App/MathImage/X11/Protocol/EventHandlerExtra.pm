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


package App::MathImage::X11::Protocol::EventHandlerExtra;
use 5.004;
use strict;
use Carp;

BEGIN {
  # weaken() if available, which means new enough Perl to have weakening,
  # and Scalar::Util with its XS code
  eval "use Scalar::Util 'weaken'; 1"
    or eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
sub weaken {} # otherwise noop
HERE
}

use vars '$VERSION';
$VERSION = 110;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  my ($class, $X, $event_handler) = @_;
  ### EventHandlerExtra new()

  my $old_event_handler = $X->{'event_handler'};
  $X->{'event_handler'} = sub {
    ### EventHandlerExtra handler sub
    &$event_handler (@_);
    goto $old_event_handler;
  };
  my %self = (X      => $X,
              old_event_handler => $old_event_handler);
  weaken($self{'X'});
  return bless \%self, $class;
}

sub DESTROY {
  my ($self) = @_;
  $self->restore;
}

sub restore {
  my ($self) = @_;
  ### EventHandlerExtra restore()
  if (my $X = $self->{'X'}) {
    if (defined (my $old_event_handler = delete $self->{'old_event_handler'})) {
      $X->{'event_handler'} = $old_event_handler;
    }
  }
}

1;
__END__
