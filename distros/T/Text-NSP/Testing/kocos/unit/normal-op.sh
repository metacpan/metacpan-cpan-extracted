#!/bin/csh
# Shell Test script to run all tests which check normal behavior of kocos.pl
# normal-op.sh version 0.01
# By Amruta Purandare 01/10/2003

# Copyright (C) 2002-2004
# Amruta Purandare, University of Minnesota, Duluth
# pura0010@umn.edu
# Ted Pedersen, University of Minnesota, Duluth
# tpederse@umn.edu

#############################################################################
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

##############################################################################

set dirlist = `ls testA*.sh`
foreach i ($dirlist)
	csh ./$i
end

rm -fr *.output
