use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'Test::OpenTracing::Interface',
    'VERSION_FROM'  => 'lib/Test/OpenTracing/Interface.pm',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/Test/OpenTracing/Interface/*/*.t',
    },
);
