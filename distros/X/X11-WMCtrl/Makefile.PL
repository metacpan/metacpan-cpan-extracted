#!/usr/bin/perl
# $Id: Makefile.PL,v 1.1 2004/01/11 22:05:53 jodrell Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'X11::WMCtrl',
    'VERSION_FROM'	=> 'lib/X11/WMCtrl.pm',
);
