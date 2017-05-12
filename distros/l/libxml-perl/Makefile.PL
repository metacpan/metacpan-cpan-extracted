#
# Copyright (C) 1998 Ken MacLeod
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# $Id: Makefile.PL,v 1.3 1999/05/24 23:25:02 kmacleod Exp $
#

use ExtUtils::MakeMaker;

$VERSION = '0.08';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'libxml-perl',
    'VERSION_FROM' => 'Makefile.PL',
    'PREREQ_PM' => { 'XML::Parser' => '2.19' },
    dist        => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
);
