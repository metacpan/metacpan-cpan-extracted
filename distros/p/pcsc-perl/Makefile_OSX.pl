#!/usr/bin/perl -w 

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to
# influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'      => 'PCSC',
    'VERSION_FROM' => 'PCSC.pm', # finds $VERSION
    'LIBS'      => ['-lCoreFoundation'],   # e.g., '-lm'
    'DEFINE'    => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'       => '-I/System/Library/Frameworks/PCSC.framework/Headers/ -I/System/Library/Frameworks/PCSC.framework/PrivateHeaders/',     # e.g., '-I/usr/include/other'
);


