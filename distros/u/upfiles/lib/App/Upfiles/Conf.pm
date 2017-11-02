# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde

# This file is part of Upfiles.
#
# Upfiles is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Upfiles is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Upfiles.  If not, see <http://www.gnu.org/licenses/>.


package App::Upfiles::Conf;
use 5.010;
use strict;
use warnings;

our $VERSION = 12;

our $upf;

sub upfiles {
  $upf->upfiles(@_);
  return 1;
}

1;
__END__

=for stopwords conf upfiles Upfiles Ryde

=head1 NAME

App::Upfiles::Conf -- conf file environment for upfiles

=head1 DESCRIPTION

The F<~/.upfiles.conf> file is run in this package.  The C<upfiles> function
operates on an Upfiles object.

=head1 SEE ALSO

L<upfiles>,
L<App::Upfiles>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/upfiles/index.html>

=head1 LICENSE

Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde

Upfiles is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Upfiles is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Upfiles.  If not, see L<http://www.gnu.org/licenses/>.

=cut
