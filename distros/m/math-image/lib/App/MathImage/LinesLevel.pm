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

package App::MathImage::LinesLevel;
use 5.004;
use strict;
use Locale::TextDomain 'App-MathImage';

use vars '$VERSION','@ISA';
$VERSION = 110;
use Math::NumSeq::All;
@ISA = ('Math::NumSeq::All');

use constant name => __('Line by Level');
use constant description => __('No numbers, instead lines showing the path taken.');
use constant oeis_anum => undef;

use constant parameter_info_array =>
  [ { name    => 'level',
      display => __('Level'),
      type    => 'integer',
      minimum => 1,
      maximum => 999,
      default => 3,
      # description => __('.'),
    } ];

1;
__END__

=for stopwords Ryde MathImage

=head1 NAME

App::MathImage::LinesLevel -- replication level line drawing

=head1 DESCRIPTION

This is a special kind of "values" which draws lines between the points of
the path through to a selectable replication level, holding the endpoints
fixed.

This is designed for paths like the KochCurve or Flowsnake where the
replication levels turn each line segment into a further shape.

The current code depends on some hard coded setups for the levels of the
various paths, and doesn't work well at all on non-replicating paths.

=head1 SEE ALSO

L<App::MathImage::Lines>,
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
