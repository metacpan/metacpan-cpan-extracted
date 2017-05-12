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
use WWW::Sucksub::Attila;
my $mot= shift;
$test=WWW::Sucksub::Attila->new(
			motif => $mot,
			debug =>1,
			logout => '/home/timo/attila.log',
			dbfile=>'/home/timo/attila.db',
			html=>'/home/timo/attila.html'
			);
$test->update(); #make db file
$test->search(); #use db file and produce html report about $mot search
#