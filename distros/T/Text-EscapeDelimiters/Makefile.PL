use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Text::EscapeDelimiters',
              VERSION_FROM  => 'lib/Text/EscapeDelimiters.pm',
              PREREQ_PM => {
                            Carp => 0,
                            Test::More => 0,
                           },
              ABSTRACT_FROM => 'lib/Text/EscapeDelimiters.pm',
              AUTHOR        => 'John Alden',
             );
