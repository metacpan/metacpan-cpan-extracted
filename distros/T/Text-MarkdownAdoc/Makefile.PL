use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'Text::MarkdownAdoc',
    VERSION_FROM     => 'lib/Text/MarkdownAdoc.pm',
    ABSTRACT_FROM    => 'lib/Text/MarkdownAdoc.pm',
    AUTHOR           => 'Sandor Patocs',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.016',
    EXE_FILES        => ['script/markdown-adoc'],
    TEST_REQUIRES    => { 'Test::More' => '0' },
    PREREQ_PM        => {},
);