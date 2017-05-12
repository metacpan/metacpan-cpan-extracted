#!/usr/bin/perl -w

# Copyright 2010, 2011, 2016 Kevin Ryde

# This file is part of PodLinkCheck.

# PodLinkCheck is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# PodLinkCheck is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PodLinkCheck.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use App::PodLinkCheck::ParseLinks;

use FindBin;
my $progfile = "$FindBin::Bin/$FindBin::Script";
print $progfile,"\n";


{
  my $parser = App::PodLinkCheck::ParseLinks->new;
  $parser->parse_file($progfile);
  foreach my $link (@{$parser->links_arrayref}) {
    my ($type, $to, $section, $linenum, $column) = @$link;
  }

  my $links_arrayref = $parser->links_arrayref;
  foreach my $link (@$links_arrayref) {
    my ($type, $to, $section, $linenum, $column) = @$link;

    $to //= '';
    $section //= '';
    print "$progfile:$linenum:$column: $type $to $section\n";
  }

  print "sections:\n";
  my $sections_hashref = $parser->sections_hashref;
  foreach my $section (sort keys %$sections_hashref) {
    print "$section\n";
  }
  exit 0;
}

__END__

=head1 FOO

L<hello
newline
newline/world>
z
z
X<index
entry
X<nested x>
newlines>
z
z
L<foo>
z
z
L<hello/world
newline
newline>
z
z
L<foo>

=over

=item BlahX<index entry>

=back
