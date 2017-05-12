# -*- mode: text -*-

use ExtUtils::MakeMaker;

WriteMakefile(NAME         => 'Text::SimpleTemplate',
              VERSION_FROM => 'SimpleTemplate.pm',
              PREREQ_PM    => {
                  FileHandle => 0,
                  Carp       => 0,
              },
              );
