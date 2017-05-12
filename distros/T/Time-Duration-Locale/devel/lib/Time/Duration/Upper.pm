# Copyright 2009, 2010, 2011, 2013, 2016 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.


package Time::Duration::Upper;
use 5.004;
use strict;
use warnings;
use Carp;
use Time::Duration::Filter from => 'Time::Duration';
use vars qw($VERSION);

print "Upper AUTOLOAD func ", \&AUTOLOAD, "\n";

$VERSION = 12;

sub _filter {
  my ($str) = @_;
  print "filter $str\n";
  return uc($str);
}

1;
__END__
