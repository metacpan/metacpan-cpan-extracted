#    XFontStruct.pm - An extension to PERL to access XFontStruct structures.
#    Copyright (C) 1996-1997  Martin Bartlett
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#
#
# IF YOUR SYSTEM DOES NOT HAVE A 'STRIP' UTILITY TO DISCARD SYMBOLS FROM
# OBJECT FILES, THEN DELETE THE 
#
#	sub MY::dynamic_lib 
#
# SUBROUTINE BELOW, OTHERWISE THIS MODULE WILL NOT COMPILE CORRECTLY
#
WriteMakefile(
    'NAME'	=> 'X11::XFontStruct',
    'VERSION_FROM'	=> 'XFontStruct.pm',
    'LIBS'	=> ['-L/usr/X11R6/lib -lX11'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> ''      # e.g., '-I/usr/include/other' 
);
 
sub MY::dynamic_lib {
	my $self = shift;
    	local *dynamic_lib;
    	my $lk=$self->MM::dynamic_lib;
	my $strip = "strip";
	$strip = "strip -f" if ($Config::Config{osname} =~ /irix/);
	$strip = "true"     if ($Config::Config{osname} =~ /sunos/);
    	$lk . "\t$strip \$@\n";
}

