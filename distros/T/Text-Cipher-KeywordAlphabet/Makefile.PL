use ExtUtils::MakeMaker;

WriteMakefile(
              NAME          => 'Text::Cipher::KeywordAlphabet',
              VERSION_FROM  => 'lib/Text/Cipher/KeywordAlphabet.pm',
              PREREQ_PM => {
                            Carp => 0,
                            Test::More => 0,
                            Text::Cipher => 0,			   
                           },
              ABSTRACT_FROM => 'lib/Text/Cipher/KeywordAlphabet.pm',
              AUTHOR        => 'John Alden',
             );
