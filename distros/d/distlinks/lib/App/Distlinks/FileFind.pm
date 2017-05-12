# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Distlinks.
#
# Distlinks is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Distlinks is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Distlinks.  If not, see <http://www.gnu.org/licenses/>.

package App::Distlinks::FileFind;
use 5.010;
use strict;
use warnings;
use File::Spec;
use Iterator::Simple;

our $VERSION = 11;

use constant _false => 0;

# dirs
# prune
# queue
#
sub new {
  my ($class, %self) = @_;
  $self{'queue_array'} ||= [];
  if (defined (my $dir = delete $self{'dir'})) {
    push @{$self{'queue_array'}}, $dir;
  }
  if (my $dirs = delete $self{'dirs'}) {
    push @{$self{'queue_array'}}, @$dirs;
  }
  $self{'prune_pred'} ||= \&_false;
  return Iterator::Simple::iterator (sub { _next(\%self) });
}

sub _next {
  my ($self) = @_;
  my $q = $self->{'queue_array'};
  if (! @$q) { return; }

  my $filename = shift @$q;
  if (-d $filename) {
    if (! $self->{'prune_pred'}->($filename)) {
      if (opendir my $fh, $filename) {
        unshift @$q,
          map { File::Spec->rel2abs($_, $filename) }
            grep { $_ ne '.' && $_ ne '..' }
              readdir $fh;
      } else {
        # warn "Skipping unreadable directory $filename";
      }
    }
  }
  return $filename;
}

1;
__END__
