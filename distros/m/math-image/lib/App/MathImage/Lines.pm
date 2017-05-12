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

package App::MathImage::Lines;
use 5.004;
use strict;
use Locale::TextDomain 'App-MathImage';

# uncomment this to run the ### lines
#use Smart::Comments;


use vars '$VERSION','@ISA';
$VERSION = 110;
use Math::NumSeq::All;
@ISA = ('Math::NumSeq::All');

use constant name => __('Lines');
use constant description => __('No numbers, instead lines showing the path taken.');
use constant oeis_anum => undef;

use constant parameter_info_array =>
  [ { name    => 'increment',
      display => __('Increment'),
      type    => 'integer',
      default => 0,
      minimum => 0,
      width   => 3,
      description => __('An N increment between line segments.  0 means the default for the path.'),
    },
    { name            => 'lines_type',
      display         => __('Lines Type'),
      type            => 'enum',
      default         => 'integer',
      choices         => [ 'integer','midpoint','rounded' ],
      choices_display => [ __('Integer'),__('Midpoint'),__('Rounded') ],
    },
    { name           => 'midpoint_offset',
      type           => 'float',
      default        => 0.50,
      decimals       => 2,
      minimum        => 0,
      maximum        => 1.00,
      step_increment => 0.05,
      page_increment => 0.2,
      when_name      => 'lines_type',
      when_values    => ['midpoint','rounded'],
    },
  ];

1;
__END__

=for stopwords Ryde MathImage

=head1 NAME

App::MathImage::Lines -- line drawing

=head1 DESCRIPTION

This is a special kind of "values" which draws lines between the points of
the path.

=head1 SEE ALSO

L<App::MathImage::LinesLevel>,
L<App::MathImage::LinesTree>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-image/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013 Kevin Ryde

Math-Image is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-Image is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-Image.  If not, see <http://www.gnu.org/licenses/>.

=cut
