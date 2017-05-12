#!/bin/csh -f
#
# Shell script to run combig.pl program on a given file
#
# combig-script.sh version 0.01
#
##############################################################################
# Copyright (C) 2002-2003
# Amruta Purandare, University of Minnesota, Duluth
# pura0010@umn.edu
# Ted Pedersen, University of Minnesota, Duluth
# tpederse@umn.edu
#
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

if($#argv != 1) then
	echo "Usage: combig-script.sh input-file"
	exit 1
endif

# accept input file from count.pl program
set infile = $1;
# accept target word
set word = $2;

count.pl $infile.out $infile
combig.pl $infile.out 

rm -f $infile.out

