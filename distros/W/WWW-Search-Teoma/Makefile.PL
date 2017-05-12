use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'	=> 'WWW::Search::Teoma',
              'VERSION' => 0.01,
              'PREREQ_PM' => {
                              'WWW::Search::Test' => 2.11,
                             },
             );
