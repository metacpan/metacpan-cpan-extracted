use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'XML::Toolset',
    VERSION       => '0.50',
    #EXE_FILES     => ['bin/xmltool'],
    EXE_FILES     => [],
    PREREQ_PM => {
        'App::Options' => 0.01,
        'App::Context' => 0.01,
        'Test::More' => 0.01,
    },
    ABSTRACT_FROM => 'lib/XML/Toolset.pm',
    AUTHOR => '"Stephen Adkins" <spadkins@gmail.com>',
);

