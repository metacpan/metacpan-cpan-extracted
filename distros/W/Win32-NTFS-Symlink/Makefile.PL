#!/usr/bin/perl -w

use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
   NAME              => 'Win32::NTFS::Symlink',
   VERSION_FROM      => 'lib/Win32/NTFS/Symlink.pm',
   PREREQ_PM         => { 'List::Util' => '1.45' },
   TEST_REQUIRES     => { 'Test::More' => 0 },
   ABSTRACT_FROM     => 'lib/Win32/NTFS/Symlink.pm',
   AUTHOR            => 'Bayan Maxim <baymax@cpan.org>',
   LICENSE           => 'perl',
   LIBS              => [''],
   DEFINE            => '',
   INC               => '-I. -Iinclude',
   OBJECT            => '$(O_FILES)'
);
