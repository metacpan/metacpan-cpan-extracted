#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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


# tcpick -i ppp0 -C -bU -T1

use 5.010;
use strict;
use warnings;
use LWP::UserAgent;
use URI;

$ENV{'NNTPSERVER'} = 'localhost';

{
  require Net::NNTP;
  my $nntp = Net::NNTP->new
    || die "Can't connect to nntp server";

  my $mess = $nntp->message;
  #    $mess =~ s/\s+ready\b.*//;
  #    $mess =~ s/^\S+\s+//;
  print "'$mess'\n";
  exit 0;
}

{
  # my $url = 'ftp://download.tuxfamily.org/user42/align-let.el.asc';
  my $url = 'news:r2l.test';

  my $uri = URI->new($url);
  print "host: ",$uri->host//'undef',"\n";

  my $ua = LWP::UserAgent->new;
  my $resp = $ua->head($url);

  print "status_line: ",$resp->status_line,"<<<end\n";
  print "headers:\n";
  print $resp->as_string;
}
