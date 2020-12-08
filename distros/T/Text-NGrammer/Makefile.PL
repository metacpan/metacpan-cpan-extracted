use ExtUtils::MakeMaker;
WriteMakefile
(
          'NAME' => 'Text::NGrammer',
          'VERSION_FROM' => 'lib/Text/NGrammer.pm',
          'PREREQ_PM' => {
             'Lingua::Sentence'	=> '0',
          },
          'INSTALLDIRS' => 'site',
          'EXE_FILES' => [],
          'PL_FILES' => {}
        )
;
