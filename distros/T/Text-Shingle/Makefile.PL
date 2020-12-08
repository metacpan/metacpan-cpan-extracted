use ExtUtils::MakeMaker;
WriteMakefile
(
          'NAME' => 'Text::Shingle',
          'VERSION_FROM' => 'lib/Text/Shingle.pm',
          'PREREQ_PM' => {
             'Text::NGrammer'     => '0',
             'Unicode::Normalize' => '0.06',
             'Lingua::Sentence'	  => '0',
          },
          'INSTALLDIRS' => 'site',
          'EXE_FILES' => [],
          'PL_FILES' => {}
        )
;
