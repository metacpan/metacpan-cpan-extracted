# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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


package App::MathImage::Prima::About;
use 5.004;
use strict;
use warnings;
use Locale::TextDomain 'App-MathImage';
use Prima; # constants
use Prima::Label;
use Prima::MsgBox;

# uncomment this to run the ### lines
#use Smart::Comments;

use vars '$VERSION';
$VERSION = 110;

sub init {
  my ($self, %profile) = @_;
  ### About init(): @_
  return $self->SUPER::init (%profile,
                             );
}
#   $self->set (name => );
#   return %profile;
# }

sub popup {
  my $text = Prima::MsgBox::message
    (__x('Math Image version {version}', version => $VERSION)
     . "\n\n"
     . __x('Running under Prima {version}', version => Prima->VERSION),
     mb::Information() | mb::Ok(),
     name => __('Math-Image: About'),
    );
}

1;
__END__
