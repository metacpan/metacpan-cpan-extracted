use ExtUtils::MakeMaker;

WriteMakefile( NAME         => "URI::Find::Delimited",
               VERSION_FROM => "lib/URI/Find/Delimited.pm",
               PREREQ_PM    => { 'Test::More'       => 0,
                                 'URI::URL'         => 0,
                                 'URI::Find'        => 0
                               }
             );
