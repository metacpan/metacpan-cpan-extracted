use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'          => 'Test::OpenTracing::Integration',
    'VERSION_FROM'  => 'lib/Test/OpenTracing/Integration.pm',
    'LICENSE'       => 'perl',
    test            => {
        TESTS       => 't/*.t t/*/*.t t/Implementation/Test/*/*.t',
    },
);
