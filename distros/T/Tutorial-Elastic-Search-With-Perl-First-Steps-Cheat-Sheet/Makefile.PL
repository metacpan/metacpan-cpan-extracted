

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Tutorial::Elastic::Search::With::Perl::First::Steps::Cheat::Sheet',
    VERSION_FROM => 'lib/Tutorial/Elastic/Search/With/Perl/First/Steps/Cheat/Sheet.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes (hernanlopes@gmail.com)',
    ABSTRACT     => 'Learn how to start using Elastic Search with perl for your apps',
    PREREQ_PM    => {
                    'Test::Simple' => 0.44,
                    'Moose' => 0,
                    'ElasticSearch' => 0,
                    'Data::Printer' => 0,
                    'Try::Tiny' => 0,
                    'File::Slurp' => 0,
                    },
);
