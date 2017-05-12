use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'XML::Validate',
              VERSION_FROM  => 'lib/XML/Validate.pm',
              EXE_FILES     => ['scripts/validxml.pl'],
              PREREQ_PM => {
								'Test::More' => 0,
              					'Test::Assertions' => 0,
              					'Log::Trace' => 0,              					
                           },
              ABSTRACT_FROM => 'lib/XML/Validate.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );
