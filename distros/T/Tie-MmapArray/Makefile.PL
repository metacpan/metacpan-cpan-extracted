# @(#) $Id: Makefile.PL,v 1.4 1999/12/28 10:13:31 andrew Exp $
# 
# Copyright (C) 1999, Ford & Mason Ltd.  All rights reserved.
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the README file.

use ExtUtils::MakeMaker;

# Uncomment the following line to compile with debug tracing
#$tracing = "-DDEBUG_TRACING";

# debugging flags,
# todo: borland, others
$debugflags = ($Config{'cc'} =~ /cl\.exe/i)
               ? "-Zi" 				# msvc
               : "-g -Wall"; 			# gcc

$optimize = "$debug_flags $tracing";

WriteMakefile(NAME         => 'Tie::MmapArray',
	      OPTIMIZE     => $optimize,
	      VERSION_FROM => 'MmapArray.pm');
