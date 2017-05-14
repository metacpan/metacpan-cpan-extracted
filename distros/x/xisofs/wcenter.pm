#   xisofs v1.3 Perl/Tk Interface to mkisofs / cdwrite
#   Copyright (c) 1997 Steve Sherwood (pariah@netcomuk.co.uk)
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

package wcenter;

use Tk;
use strict;

sub position
{
	my ($window, $width, $height) = @_;

	my $sw = $window->screenwidth();
	my $sh = $window->screenheight();
 
	my $x = int($sw / 2) - int($width/2);
	my $y = int($sh / 2) - int($height/2);

	my $g = join('x',$width,$height);
	$window->geometry("$g+$x+$y");
}

sub offset
{
	my ($window, $dx, $dy) = @_;

	$_ = $main::mw->geometry();
	my ($w,$h,$x,$y) = /(\d+)x(\d+)\+(\d+)\+(\d+)/;

	$x += $dx;
	$y += $dy;

	$window->geometry("+$x+$y");
}

1;
