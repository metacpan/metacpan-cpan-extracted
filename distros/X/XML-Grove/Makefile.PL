#
# Copyright (C) 1998 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Makefile.PL,v 1.2 1999/04/30 18:11:45 kmacleod Exp $
#

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XML::Grove',
    'VERSION_FROM' => 'lib/XML/Grove.pm',
    'PREREQ_PM' => { 'XML::Parser' => '2.19' },
    dist        => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
);
