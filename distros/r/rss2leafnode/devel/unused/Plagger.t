#!/usr/bin/perl

# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde

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

use strict;
use warnings;
use Test::More tests => 16;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $want_version = 79;

SKIP: {
  if (! eval { require Plagger::Plugin::Publish::Rnews; }) {
    skip 'Plagger::Plugin::Publish::Rnews doesn\'t load', 4;
  }
  cmp_ok ($Plagger::Plugin::Publish::Rnews::VERSION, '>=', $want_version,
          'VERSION variable');
  cmp_ok (Plagger::Plugin::Publish::Rnews->VERSION,  '>=', $want_version,
          'VERSION class method');
  { ok (eval { Plagger::Plugin::Publish::Rnews->VERSION($want_version); 1 },
        "VERSION class check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { Plagger::Plugin::Publish::Rnews->VERSION($check_version); 1 },
        "VERSION class check $check_version");
  }
}

SKIP: {
  if (! eval { require Plagger::Plugin::Filter::YahooLinks; }) {
    skip 'Plagger::Plugin::Filter::YahooLinks doesn\'t load', 4;
  }
  cmp_ok ($Plagger::Plugin::Filter::YahooLinks::VERSION, '>=', $want_version,
          'VERSION variable');
  cmp_ok (Plagger::Plugin::Filter::YahooLinks->VERSION,  '>=', $want_version,
          'VERSION class method');
  { ok (eval { Plagger::Plugin::Filter::YahooLinks->VERSION($want_version); 1 },
        "VERSION class check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { Plagger::Plugin::Filter::YahooLinks->VERSION($check_version); 1 },
        "VERSION class check $check_version");
  }
}

SKIP: {
  if (! eval { require Plagger::Plugin::Filter::GoogleListPost; }) {
    skip 'Plagger::Plugin::Filter::GoogleListPost doesn\'t load', 4;
  }
  cmp_ok ($Plagger::Plugin::Filter::GoogleListPost::VERSION,'>=',$want_version,
          'VERSION variable');
  cmp_ok (Plagger::Plugin::Filter::GoogleListPost->VERSION, '>=',$want_version,
          'VERSION class method');
  { ok (eval { Plagger::Plugin::Filter::GoogleListPost->VERSION($want_version); 1 },
        "VERSION class check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { Plagger::Plugin::Filter::GoogleListPost->VERSION($check_version); 1 },
        "VERSION class check $check_version");
  }
}

SKIP: {
  if (! eval { require Plagger::Plugin::Filter::FormatText; }) {
    skip 'Plagger::Plugin::Filter::FormatText doesn\'t load', 4;
  }
  cmp_ok ($Plagger::Plugin::Filter::FormatText::VERSION, '>=', $want_version,
          'VERSION variable');
  cmp_ok (Plagger::Plugin::Filter::FormatText->VERSION,  '>=', $want_version,
          'VERSION class method');
  { ok (eval { Plagger::Plugin::Filter::FormatText->VERSION($want_version); 1 },
        "VERSION class check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { Plagger::Plugin::Filter::FormatText->VERSION($check_version); 1 },
        "VERSION class check $check_version");
  }
}

exit 0;
