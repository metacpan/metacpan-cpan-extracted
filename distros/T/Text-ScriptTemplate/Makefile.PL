# -*- mode: text -*-

use ExtUtils::MakeMaker;

WriteMakefile(NAME         => 'Text::ScriptTemplate',
              VERSION_FROM => 'ScriptTemplate.pm',
              PREREQ_PM    => {
                  Carp       => 0,
                  FileHandle => 0,
              },
              );
