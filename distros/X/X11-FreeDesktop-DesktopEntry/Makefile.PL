#!/usr/bin/perl
# $Id: Makefile.PL,v 1.1.1.1 2005/01/01 19:29:35 jodrell Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'X11::FreeDesktop::DesktopEntry',
    'VERSION_FROM'	=> 'lib/X11/FreeDesktop/DesktopEntry.pm',
);
