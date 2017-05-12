use ExtUtils::MakeMaker;
WriteMakefile
(
          'NAME' => 'Test::Out',
          'VERSION_FROM' => 'lib/Test/Out.pm',
          'PREREQ_PM' => {
                           'Test::Builder' => '0.17',
                           'Carp' => '1.04',
                           'Carp::Assert' => '0.20',
                         },
          'INSTALLDIRS' => 'site',
          'EXE_FILES' => [],
          'PL_FILES' => {}
        )
;
