use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME                => 'Text::Identify::BoilerPlate',
              AUTHOR              => 'Lars Nygaard <lars.nygaard@inl.uio.no>',
              VERSION_FROM        => 'lib/Text/Identify/BoilerPlate.pm',
              ABSTRACT_FROM       => 'lib/Text/Identify/BoilerPlate.pm',
              EXE_FILES => ['bin/rem-boilerplate-text'],
              PL_FILES            => {},
              PREREQ_PM => {
                            'Test::More' => 0,
                            'Getopt::Mixed' => 0,
                           },
              dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean               => { FILES => 'Text-Identify-BoilerPlate-*' },
             );
