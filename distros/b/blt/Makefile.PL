# Copyright (C) 2007-8 Thomas Thurman <tthurman@gnome.org>
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA.

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME            => 'blt',
  AUTHOR          => 'Thomas Thurman <tthurman@gnome.org>',
  VERSION_FROM    => 'lib/App/BLT.pm',
  PREREQ_PM       => {
    'Getopt::Long'  => 0,
    'XML::Tiny'     => 0,
    'Test::More'    => 0,
  },
  PM              => {
    'lib/App/BLT.pm' => '$(INST_LIBDIR)/App/BLT.pm'
  },
  EXE_FILES       => [ 'bin/blt' ],
);
