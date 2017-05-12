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

use 5.004;
use strict;
use Test::Without::Shm;

use Test;
my $test_count = (tests => 4)[1];
plan tests => $test_count;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# supplied with perl 5.005, might not be available earlier
if (! eval { require IPC::SysV; 1 }) {
  MyTestHelpers::diag ('IPC::SysV not available -- ',$@);
  foreach (1 .. $test_count) {
    skip ('IPC::SysV not available', 1, 1);
  }
  exit 0;
}

#------------------------------------------------------------------------------

{
  my $eval = eval { shmget (IPC::SysV::IPC_PRIVATE(),
                      5000,
                      IPC::SysV::IPC_CREAT() | 0666); # world read/write
                     1;
                   };
  my $err = $@;
  ok (! defined $eval, 1);
  ok ($err, "/^shmget not implemented/");
}
{
  Test::Without::Shm->mode('nomem');
  my $shmid = shmget (IPC::SysV::IPC_PRIVATE(),
                      5000,
                      IPC::SysV::IPC_CREAT() | 0666); # world read/write
  my $errno = $!+0; # number
  ok (! defined $shmid, 1);
  require POSIX;
  ok ($errno, POSIX::ENOMEM());
}

Test::Without::Shm->mode('normal');

exit 0;
