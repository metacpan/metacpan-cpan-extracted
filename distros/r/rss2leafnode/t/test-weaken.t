#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# RSS2Leafnode is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use App::RSS2Leafnode;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

if (! eval "use Test::Weaken 2.000; 1") {
  plan skip_all => "due to Test::Weaken 2.000 not available -- $@";
}
if (! eval "use Test::Weaken::ExtraBits 1; 1") {
  plan skip_all => "due to Test::Weaken::ExtraBits not available -- $@";
}

plan tests => 2;

diag ("Test::Weaken version ", Test::Weaken->VERSION);


#-----------------------------------------------------------------------------

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub { return App::RSS2Leafnode->new },
     });
  is ($leaks, undef, 'deep garbage collection -- new()');
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $r2l = App::RSS2Leafnode->new;
         my $ua = $r2l->ua;
         return [ $r2l, $ua ];
       },
       # handler funcs set in ua()
       ignore => \&Test::Weaken::ExtraBits::ignore_global_functions,
     });
  is ($leaks, undef, 'deep garbage collection -- new() and ua()');

  if ($leaks) {
    if (defined &explain) { diag "Test-Weaken ", explain $leaks; }
    my $unfreed = $leaks->unfreed_proberefs;
    foreach my $proberef (@$unfreed) {
      diag "  unfreed $proberef";
    }
    foreach my $proberef (@$unfreed) {
      diag "  search $proberef";
      MyTestHelpers::findrefs($proberef);
    }
  }
}

exit 0;
