#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Distlinks.
#
# Distlinks is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Distlinks is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Distlinks.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More tests => 11;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require App::Distlinks::DBI;

{
  my $want_version = 11;
  is ($App::Distlinks::DBI::VERSION, $want_version, 'VERSION variable');
  is (App::Distlinks::DBI->VERSION,  $want_version, 'VERSION class method');

  ok (eval { App::Distlinks::DBI->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { App::Distlinks::DBI->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# diagonstics

# {
#   my $t = time();
#   diag "time() is $t";
#   my @gm = gmtime($t);
#   diag "gmtime() has ",scalar(@gm)," values";
#   diag "gmtime() is ", explain \@gm;
# }

#------------------------------------------------------------------------------

{
  my $dbh = App::Distlinks::DBI->instance;
  isa_ok ($dbh, 'DBI::db');
  isa_ok ($dbh, 'App::Distlinks::DBI::db');

  my $url = 'http://distlinks.dbi.test.script.invalid/';
  my $anchor = 'sect';
  my $not_anchor = 'nosuchanchor';

  $dbh->do('DELETE FROM page WHERE url=?', undef, $url);
  # not sure if can rely on DELETE CASCADE ...
  $dbh->do('DELETE FROM anchor WHERE url=?', undef, $url);
  {
    my $info = $dbh->read_page ($url);
    diag "after delete: ", explain $info;
    is_deeply ($info, {}, "read_page() nothing for url");
  }
  {
    my $info = $dbh->read_page ($url, $anchor);
    diag "after read_page: ", explain $info;
    is_deeply ($info, { anchor_not_found => 1,
                        have_anchors => []},
               "read_page() with anchor, nothing for url");
  }

  $dbh->write_page ({ url => $url,
                      is_success => 1,
                      status_code => 200,
                      status_line => '200 OK',
                      anchors => [ $anchor ] });
  {
    my $info = $dbh->read_page ($url);
    # diag explain $info;
    ok ($info->{'is_success'},
        "read_page() after write");
  }
  {
    my $info = $dbh->read_page ($url, $anchor);
    ok ($info->{'is_success'},
        "read_page() and anchor");
  }
  {
    my $info = $dbh->read_page ($url, $not_anchor);
    ok ($info->{'is_success'},
        "read_page() nosuchanchor");
  }

  diag "expire ...";
  $dbh->expire;
  diag "vacuum ...";
  $dbh->vacuum;

  diag "finished";
}

exit 0;
