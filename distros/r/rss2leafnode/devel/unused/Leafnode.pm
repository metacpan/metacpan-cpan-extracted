# Copyright 2007, 2008, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

package News::Rnews::Leafnode;
use strict;
use warnings;
use base 'News::Rnews';

our $VERSION = 79;


sub new {
  my ($class, %options) = @_;
  $options{'rnews_program'} ||= [ @News::Rnews::rnews_program, '-e' ];
  return $class->SUPER::new ($class, %options);
}

1;
__END__
