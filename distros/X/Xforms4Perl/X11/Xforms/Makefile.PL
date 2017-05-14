#    Xforms.pm - An extension to PERL to access XForms functions.
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
# NOTE ON 'INC =>' AND 'LIBS =>'
#
#       If the forms.h is not in your default include directory path
#       then add '-I/your/path' to 'INC =>'
#
#       Similarly for X11/lib - if its not in your default lib path
#       then add '-L/your/path' at the start of 'LIBS =>'
#
#	OPENGL:
#		If you have OpenGL and want that functionality compiled into
#		the extension then you must do the following:
#			
#			1) Change the DEFINE hash to be like so:
#				DEFINE => '-DXFOPENGL',
#			2) Add the name of the OpenGL library to the list
#			   of libraries under LIBS
#
WriteMakefile(
       CONFIG => [qw(osname)],
       DEFINE => '',
       INC => '',
       LIBS => [ '-L/usr/X11R6/lib -lforms -lX11 -lXpm -lm' ],
       NAME => 'X11::Xforms',
       PM => {'Xforms.pm' => '$(INST_LIBDIR)/Xforms.pm'},
       VERSION_FROM => 'Xforms.pm.skel',
       'clean' => { FILES => "*.tc Xforms.pm"}
);

sub MY::postamble {
#
# This subroutine checks to see if the constants package
# is installed. If so, Xforms.pm is used as-is. If not, then
# it is filtered to change all 'use constant' lines to subroutines.
#
	my $self = shift;
   	local *postamble;
   	my $post=$self->MM::postamble;
	my $pmrule = 	"\n#\n#Create Xforms.pm from Xforms.pm.skel\n#\n" .
					"Xforms.pm:\tXforms.pm.skel\n\t";
	$testcon = "use constant TESTCON => 0; 1";
	if (eval($testcon))
	{
		$pmrule .= '$(CP) Xforms.pm.skel Xforms.pm';
	}
	else
	{
		$pmrule .= '$(PERL) -n -p -e ' . "'" . 's/use\s*constant\s*(\w*)\s*=>\s*(\S*)\s*;/sub \1() { \2; }/g' . "'" . ' Xforms.pm.skel > Xforms.pm';
	}
	$post . $pmrule . "\n"
}

sub MY::dynamic_lib {
	my $self = shift;
   	local *dynamic_lib;
   	my $lk=$self->MM::dynamic_lib;
	my $strip = "strip";
	$strip = "strip -f" if ($Config::Config{osname} =~ /irix/);
	$strip = "true"     if ($Config::Config{osname} =~ /sunos/);
   	$lk . "\t$strip \$@\n";
}

sub MY::xs_c {
	my $self = shift;
   	local *xs_c;
   	$_=$self->MM::xs_c;
	s/(\$\(MV\)|mv)\s*\$\*.tc/.\/tweakc \$*.tc >/;
	$_;
}


sub MY::xs_o {
	my $self = shift;
    local *xs_o;
    $_=$self->MM::xs_o;
	s/(\$\(MV\)|mv)\s*xstmp.c/.\/tweakc xstmp.c >/;
	$_;
}

