# Copyright 2009 Kevin Ryde

# This file is part of Tie-TZ.
#
# Tie-TZ is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.

package Test::POSIX::TzsetNotImplemented;
use strict;
use warnings;
use POSIX ();

sub Test::POSIX::TzsetNotImplemented_tzset {
  require Carp;
  Carp::croak("POSIX::tzset not implemented on this architecture");
}

# POSIX.xs doesn't autoload its funcs does it? only its constants?
# Give tzset() an initial run just in case.
eval { POSIX::tzset() };
{ no warnings 'redefine';
  *POSIX::tzset = \&Test::POSIX::TzsetNotImplemented_tzset;
}

1;

=head1 NAME

Test::POSIX::TzsetNotImplemented - fake POSIX::tzset "not implemented"

=head1 SYNOPSIS

 perl -Idevel -MTest::POSIX::TzsetNotImplemented ...

=head1 DESCRIPTION

B<Caution: This is at "trying an idea" stage!>

C<Test::POSIX::TzsetNotImplemented> sets C<POSIX::tzset()> to a fake
function which croaks with

    POSIX::tzset not implemented on this architecture

as per the error you get on old systems without C<tzset>.  The idea is to
exercise code which might depend on C<tzset> or adapt itself to that
function not available.

Even in the absense of C<tzset> it's possible setting C<$ENV{'TZ'}> still
influences the timezone, in fact that's so on most systems.  So
C<Test::POSIX::TzsetNotImplemented> doesn't stop timezones working
altogether, just the C<tzset> function.

You must have C<-MTest::POSIX::TzsetNotImplemented> or C<use
Test::POSIX::TzsetNotImplemented> early in a program, since the change to
C<POSIX::tzset> doesn't influence any modules where that function has
already been imported, or anywhere a coderef C<\&POSIX::tzset> has already
been taken.

=head1 SEE ALSO

L<POSIX>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/tie-tz/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009 Kevin Ryde

Tie-TZ is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Tie-TZ.  If not, see L<http://www.gnu.org/licenses/>.

=cut
