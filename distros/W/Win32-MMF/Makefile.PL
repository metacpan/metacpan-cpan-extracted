# Makefile for Win32::MMF (Memory Mapped File)
# Copyright (C) 2004 Roger Lee. All Rights Reserved.
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.
#
# $Id: Makefile.PL,v 1.1 2004/02/05 15:51:46 Roger Lee Exp $
# ---
# $Log: Makefile.PL,v $
# Revision 1.1  2004/02/05 15:51:46  Roger Lee
# Initial release of Win32::MMF.
#

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		    => 'Win32::MMF',
    'VERSION_FROM'	=> 'MMF.pm',
    'PREREQ_PM'		=> {},
    'LIBS'		    => [],
    'DEFINE'		=> '',
    'INC'		    => '',
);
