use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Vlc::Engine',
    ABSTRACT          => 'An embedded for VLC Player',
    VERSION_FROM      => 'lib/Vlc/Engine.pm', 
    PREREQ_PM         => {
        'strict'      => 0,
        'utf8'        => 0,
        'warnings'    => 0,
        'URI::Escape' => 0,
    },
    TEST_REQUIRES     => {'Test::More' => 0,},
    ABSTRACT_FROM     => 'lib/Vlc/Engine.pm',
    AUTHOR            => 'James Axl <jamesaxl@falseking.org>',
    LICENSE           => 'perl',
    test => {'TESTS'  => 't/*.t',} ,
    LIBS              => ['-lvlc'],
    DEFINE            => '',
    INC               => '-I.',
);
