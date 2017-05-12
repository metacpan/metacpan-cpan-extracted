use ExtUtils::MakeMaker;

WriteMakefile( NAME         => "Wiki::Toolkit::Plugin::Locator::Grid",
	       VERSION_FROM => "lib/Wiki/Toolkit/Plugin/Locator/Grid.pm",
	       PREREQ_PM    => { 'Wiki::Toolkit' => 0,
			         'Test::More' => 0,
				 'Carp' => 0
                               },
               clean => { FILES => "t/sqlite-test.db t/sii-db-file-test.db/ t/plucene/" }
	     );

