use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Wx::Perl::FSHandler::UNC',
              VERSION_FROM  => 'lib/Wx/Perl/FSHandler/UNC.pm',
              PREREQ_PM => {
                            Test::More => 0,
                            Wx => 0,
                            IO::File => 0,
                           },
              ABSTRACT_FROM => 'lib/Wx/Perl/FSHandler/UNC.pm',
              AUTHOR        => 'British Broadcasting Corporation',
             );
