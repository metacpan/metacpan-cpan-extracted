#!/usr/bin/perl -w

# Copyright 2009, 2010, 2012, 2014, 2015 Kevin Ryde

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
use FindBin;
use App::Upfiles;
use File::Slurp;


# uncomment this to run the ### lines
#use Smart::Comments;

mkdir ('/tmp/upf');
mkdir ('/tmp/upf/sub');
if (! -f '/tmp/upf/sub/foo.txt') {
  system ('echo hello >/tmp/upf/sub/foo.txt');
  system ('echo hi    >/tmp/upf/bar.txt');
  # File::Slurp::write_file("/tmp/upf/new\nline.txt");
}
system ('echo quux  > /tmp/upf/quux.txt');
system ('echo xyzzy > /tmp/upf/xyzzy.txt');


my $upf = App::Upfiles->new (config_filename => "$FindBin::Bin/upf.conf");
unshift @ARGV,
  '--verbose=2',
  # '-n',
  '--recheck',
  ;

$upf->command_line;
