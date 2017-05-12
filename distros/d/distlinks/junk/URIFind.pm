# Copyright 2009 Kevin Ryde

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

package App::Distlinks::URIFind;
use strict;
use warnings;
use base 'URI::Find';

# my %exclude_schemes = (mailto => 1,
#                        news   => 1,
#                       );

#     $url =~ s/['.,)]+$//;          # close quote, comma, full stop
#     # $url =~ s/\)[,.]?$//;         # close paren
#     #    $url =~ s/(\.[a-z]+)\.$/$1/;  # full stop after suffix


sub uri_re {
  my ($self) = @_;
  my $re = $self->SUPER::uri_re;

  # @uref{} or @url{} up to } or comma, so as not to include comma part
  return "(?:$re)|\@ur(?:ef|l){[^,}]+";
}

sub decruft {
  my ($self, $url) = @_;

  my $start_cruft = '';

  if (# disallow things with variable substitutions "foo$" or "$(" or "${"
      $url =~ /\$$|\$[({]/

      # disallow all mailto
      || $url =~ /^mailto:/

      # demand file:/ so as not to match "file:line:" etc text
      || $url =~ m{^file:[^/]}

      # hostname in http, to avoid fragments "http://"
      || $url =~ m{^http://[^a-zA-Z0-9]}

      # mismatches
      || $url =~ /^<[A-Z]/

     ) {
    $url = '';

  } elsif ($url =~ /^(\@ur(ef|l){)(.*)/) {
    $start_cruft =  $1;
    $url = $3;
  }

  $url =~ s/\@comma{}/,/g;  # some of my CBOT in .texi

  $url = $self->SUPER::decruft($url);
  $self->{'start_cruft'} = $start_cruft . $self->{'start_cruft'};

  return $url;
}

1;
__END__
