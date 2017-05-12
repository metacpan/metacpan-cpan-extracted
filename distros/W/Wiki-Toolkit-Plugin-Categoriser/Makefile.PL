use ExtUtils::MakeMaker;
WriteMakefile(
           (MM->can('signature_target') ? (SIGN => 1) : ()),
           NAME         => "Wiki::Toolkit::Plugin::Categoriser",
           VERSION_FROM => "lib/Wiki/Toolkit/Plugin/Categoriser.pm",
           PREREQ_PM    => { 'Wiki::Toolkit' => 0, 
                             'Test::More' => 0,
		                     'Carp' => 0
                           },
           clean => { FILES => "t/sqlite-test.db t/sii-db-file-test.db" }
          );
