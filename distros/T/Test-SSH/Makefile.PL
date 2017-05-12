use ExtUtils::MakeMaker;
use utf8;

WriteMakefile( NAME          => 'Test::SSH',
               VERSION_FROM  => 'lib/Test/SSH.pm',
               PREREQ_PM     => { Test::More => '0',
                                  URI => '1.60',
                                  Tie::IxHash => '0',
                                },
               ABSTRACT_FROM => 'lib/Test/SSH.pm',
               AUTHOR        => 'Salvador Fandiño <sfandino@yahoo.com>',
               META_MERGE    => {
                   resources => {
                       repository => 'https://github.com/salva/p5-Test-SSH',
                   },
               },
);

