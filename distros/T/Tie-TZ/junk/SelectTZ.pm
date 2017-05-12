# Copyright 2007, 2008, 2009 Kevin Ryde

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



# This was an idea for a scope-based object sitting on an old value, doing a
# tzset on setting and restoring,
#
#    { my $selector = SelectTZ->new ('GMT');
#      do_something_in_gmt();
#      ...
#      $selector->set('Asia/Tokyo');
#      do_something_in_japan();
#    }
#
# This is a little in the style of SelectSaver.pm for the "select()" current
# output filehandle.
#
# The danger is that if you don't properly nest your selectors then you
# could end up with the wrong "old" value restored.  The "local $TZ" in
# Tie::TZ lets Perl handle the restore order.
#



package SelectTZ;
use strict;
use warnings;
use POSIX ();

sub new {
  my ($class, $tz) = @_;

  my $self = bless { old_tz => $ENV{'TZ'} }, $class;
  $self->set ($tz);
  return $self;
}

sub set {
  my ($self, $tz) = @_;

  # if timezone undef, or if it's the same as the current zone, then no tzsets
  if (! defined $tz || $tz eq '') {
    return;
  }
  my $old_tz = $self->{'old_tz'};
  if (defined $old_tz && $tz eq $old_tz) {
    return;
  }

  $ENV{'TZ'} = $tz;
  POSIX::tzset();
}

sub DESTROY {
  my ($self) = @_;
  my $old_tz = $self->{'old_tz'};
  if (defined $old_tz) {
    $ENV{'TZ'} = $old_tz;
  } else {
    delete $ENV{'TZ'};
  }
  POSIX::tzset();
}

1;
__END__
