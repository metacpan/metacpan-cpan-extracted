use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'	=> 'WWW::Search::Jobserve',
              'VERSION' => 1.02,
              'PREREQ_PM' => {
			      'WWW::Search::Test' => 2.12,
                             },
             );
