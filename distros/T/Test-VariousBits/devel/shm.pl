#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-VariousBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test::Without::Shm;
use IPC::SysV;

# uncomment this to run the ### lines
use Smart::Comments;

require IPC::SysV;
Test::Without::Shm->mode('nomem');
Test::Without::Shm->mode('normal');
my $shmid = shmget (IPC::SysV::IPC_PRIVATE(),
                    5000,
                    IPC::SysV::IPC_CREAT() | 0666); # world read/write
print $shmid,"\n";

Test::Without::Shm->mode('notimp');
my $var;
if (! shmread($shmid,$var,0,1)) {
  print "shmread: $!\n";
}
# shmwrite
