
# $Id: Unix.pm,v 1.3 2001/09/19 18:32:29 nwiger Exp $
####################################################################
#
# Copyright (c) 2000 Nathan Wiger <nate@sun.com>
# 
# This module simply exports a time() function which overrides the
# builtin time, forcing it to return the seconds since the UNIX
# epoch on all platforms. It also provides a systime() function for
# returning the local system's time.
#
####################################################################
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.
#
####################################################################

require 5.003;
package Time::Unix;

use Time::Local;

use strict;
use vars qw(@EXPORT @ISA $VERSION);
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(time systime);

# Set up our time diff based on the difference in seconds
# between the UNIX epoch and the epoch on a given platform
my $DAY_SECS  = 86400;
my $TIME_OFFSET = ($^O eq "MacOS")
    ? (-24107 * $DAY_SECS) -
        sprintf "%+0.4d", (timelocal(localtime) - timelocal(gmtime))
    : 0;

sub time () { CORE::time() + $TIME_OFFSET }

# Dang typeglobs don't work right on CORE functions...
sub systime () { CORE::time() }

1;   # Hopefully Perl 6 will lose this...

__END__

=head1 NAME

Time::Unix - Force time() to return seconds since UNIX epoch

=head1 SYNOPSIS

   use Time::Unix;     # time() now returns UNIX epoch seconds

=head1 DESCRIPTION

This module does one thing: It imports a new version of time()
that returns seconds since the UNIX epoch on ALL platforms.
It is intended mainly as a proof-of-concept for the below Perl 6
RFC.

In addition to importing a time() function, it also imports
a systime() function which gives you direct access to the
system's native epoch (i.e., what time() would return if you
hadn't used this module).

This doesn't do anything useful on UNIX platforms, so don't
do that.

=head1 REFERENCES

See http://dev.perl.org/rfc/99.html for a complete description.

=head1 ACKNOWLEDGEMENTS

Thanks to Chris Nandor <pudge@pobox.com> for the MacOS time code.

=head1 AUTHOR

Copyright (c) 2000, Nathan Wiger <nate@sun.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

