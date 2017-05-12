#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

# This file is part of PodLinkCheck.
#
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

{
  package MyParser;
  use base 'Pod::Simple';
  use Data::Dumper;

  sub _handle_element_start {
    my ($self, $element_name, $attr_hash) = @_;
    print "$element_name\n";
    print Data::Dumper->Dump([$attr_hash]);
    print "\n";
  }
}

my $parser = MyParser->new();
$parser->parse_string_document(<<HERE);

=pod

L<login.conf(5)>

HERE

exit 0;
