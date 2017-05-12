use ExtUtils::MakeMaker;
use strict;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VJF::Emphase',
    VERSION_FROM      => 'lib/VJF/Emphase.pm', 
    PREREQ_PM         => {'Getopt::Lucid' => 0.16},
    LIBS              => ['-lm'], # e.g., '-lm',
    OPTIMIZE          => '-O2',
    INC               => '-I.', 
    CCFLAGS           => '-w',
    OBJECT            => 'Emphase.o'
);
