################################################################################
#
# $Project: /VCS-SnapshotCM $
# $Author: mhx $
# $Date: 2004/09/05 16:25:01 +0200 $
# $Revision: 5 $
# $Snapshot: /VCS-SnapshotCM/0.02 $
# $Source: /Makefile.PL $
#
################################################################################
# 
# Copyright (c) 2002-2003 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

use 5.6.0;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'VCS::SnapshotCM',
  VERSION_FROM  => 'lib/VCS/SnapshotCM/Tools.pm',
  PREREQ_PM     => { 'Data::Dumper'    => 0,
                     'File::Temp'      => 0,
                     'Getopt::Long'    => 0,
                     'Pod::Usage'      => 0,
                     'POSIX'           => 0,
                     'Term::ANSIColor' => 0,
                     'Text::Wrap'      => 0,
                     'Text::Tabs'      => 0,
                     'Time::Local'     => 0,
                   },
  EXE_FILES     => [qw( bin/wannotate bin/whistory )],
  AUTHOR        => 'Marcus Holland-Moritz <mhx@cpan.org>',
);
