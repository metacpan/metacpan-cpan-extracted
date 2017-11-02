#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Upfiles.
#
# Upfiles is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Upfiles is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Upfiles.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use App::Upfiles;
use Scalar::Util;

my $up = App::Upfiles->new;
my $dbh = $up->dbh ('/tmp/x.sqdb');

my $sth = $dbh->prepare ('SELECT remote,filename FROM sent');
my $aref = $dbh->selectall_arrayref($sth);

$dbh->begin_work;

foreach my $row (@$aref) {
  my ($remote, $filename) = @$row;

  my ($mtime) = $dbh->selectrow_array
    ('SELECT mtime FROM sent WHERE remote=? AND filename=?',
     undef, $remote, $filename);
  if (! defined $mtime) {
    die "Oops, mtime undef";
  }

  if (Scalar::Util::looks_like_number ($mtime)) {
    $mtime = App::Upfiles::timet_to_timestamp($mtime);
    print "$mtime\n";

    $dbh->do ('UPDATE sent SET mtime=? WHERE remote=? AND filename=?',
              undef, $mtime, $remote, $filename);
  }
}

$dbh->commit;
exit 0;
