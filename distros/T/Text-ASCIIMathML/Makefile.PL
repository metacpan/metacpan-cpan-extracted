require 5.6.1;

use strict;
use warnings;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'Text::ASCIIMathML',
    AUTHOR         => 'Mark Nodine <mnodine@alum.mit.edu>',
    ABSTRACT       => 'Perl implementation of ASCIIMathML parser',
    VERSION_FROM   => 'lib/Text/ASCIIMathML.pm',
    PREREQ_PM      => {}, # e.g., Module::Name => 1.1
    clean          => { FILES => 'Text-ASCIIMathML-*' },
    dist           => { COMPRESS => 'gzip', SUFFIX => '.gz' },
);
