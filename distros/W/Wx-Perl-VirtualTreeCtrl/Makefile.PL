use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Wx::Perl::VirtualTreeCtrl',
              VERSION_FROM  => 'lib/Wx/Perl/VirtualTreeCtrl.pm',
              PREREQ_PM => {
                            Test::More => 0,
                            Wx => 0.23,
                           },
              ABSTRACT_FROM => 'lib/Wx/Perl/VirtualTreeCtrl.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );
