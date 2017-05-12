#!/usr/bin/perl 
#***************************************************************************
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#***************************************************************************
use WWW::Sucksub::Divxstation;
my $mot= shift;
my $test= WWW::Sucksub::Divxstation->new(
						dbfile=> '/home/timo/sksb_divxstationc.db',
						html =>'/home/timo/sksb_divxstationc.html',
						motif=> $mot,
						debug=> 1,
						logout=>'/home/timo/sksb_divxstationc.txt',
						);


$test->update();
$test->cookies_file('/home/timo/cookis.txt');
$test->search();

#
#
