#!/usr/bin/perl -w

# Copyright 2009, 2010, 2012, 2014 Kevin Ryde

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
use Net::FTP;
use Tie::StdHandle;
use POSIX;

{
  package MyTie;
  use base 'Tie::StdHandle';
  my $reads = 0;
  # sub OPEN {
  # }
  sub READ {
    die;
    if ($reads++ <= 100) {
      $_[1] = 'abc';
      return 3;
    } else {
      die;
      return 0;
      print "Pretend read error\n";
      $! = POSIX::EIO();
      return undef;
    }
  }
}


my $hostname = "localhost";

my $ftp = Net::FTP->new($hostname)
  or die "Cannot connect: $@";

$ftp->login("anonymous",'')
  or die "Cannot login: ", $ftp->message;

$ftp->cwd("/pub")
  or die "Cannot cwd: ", $ftp->message;

# $ftp->delete("dummy.txt");

# {
#   my $ret = $ftp->put ('/etc/motd', 'one.txt');
#   if (defined $ret) {
#     print "remote filename: $ret\n";
#   } else {
#     print "Cannot put: ", $ftp->message;
#   }
# }
# {
#   my $ret = $ftp->put ('/etc/motd', 'one.txt.tmp');
#   if (defined $ret) {
#     print "remote filename: $ret\n";
#   } else {
#     print "Cannot put: ", $ftp->message;
#   }
# }
# 
{
  my @lines = $ftp->dir()
    or die "Cannot dir: ", $ftp->message;
  foreach (@lines) { print "$_\n"; }
}

# $ftp->rename('one.txt.tmp','one.txt')
#   or die "Cannot rename: ", $ftp->message;

tie *FH, 'MyTie', '</etc/motd';
my $ret = $ftp->put_unique (\*FH, 'dummy.txt');
if (defined $ret) {
  print "remote filename: $ret\n";
} else {
  print "Cannot put: ", $ftp->message;
}

{
  my @lines = $ftp->dir()
    or die "Cannot dir: ", $ftp->message;
  foreach (@lines) { print "$_\n"; }
}

$ftp->quit;
