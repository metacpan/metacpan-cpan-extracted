#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2016 Kevin Ryde

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
use App::PodLinkCheck::ParseSections;
use Test::More tests => 13;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

#------------------------------------------------------------------------------
{
  my $want_version = 15;
  is ($App::PodLinkCheck::ParseSections::VERSION, $want_version, 'VERSION variable');
  is (App::PodLinkCheck::ParseSections->VERSION,  $want_version, 'VERSION class method');
  ok (eval { App::PodLinkCheck::ParseSections->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { App::PodLinkCheck::ParseSections->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $plc = App::PodLinkCheck::ParseSections->new;
  is ($plc->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $plc->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $plc->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}


#------------------------------------------------------------------------------
# parse

foreach my $elem (
                  # item-number
                  [{'Name' => 1}, <<'HERE'],

=over

=item 1.

Name

Some content

=back

HERE

                  # item-text
                  [{'foo'=>1}, <<'HERE'],

=over

=item foo

Some content

=back

HERE

                  # item-bullet
                  [{'Hello World' => 1,
                    'Hello'       => 1}, <<'HERE'],

=over

=item * Hello World

Some para content

=back

HERE

                  # head1
                  [{'SYNOPSIS' => 1}, <<'HERE'],
=head1 SYNOPSIS
HERE

                  # head2
                  [{'Other Notes' => 1,
                    'Other'       => 1}, <<'HERE'],
=head2 Other Notes
HERE

                  # head3
                  [{'Yet More Notes' => 1,
                    'Yet'            => 1}, <<'HERE'],
=head3 Yet More Notes
HERE
                 ) {
  my ($want, $str) = @$elem;
  my $parser = App::PodLinkCheck::ParseSections->new;
  $parser->parse_string_document ($str);
  my $got = $parser->sections_hashref;
  diag "keys: ",join(',',sort keys %$got);

  is_deeply ($got, $want, "parse:\n$str");
}

exit 0;
