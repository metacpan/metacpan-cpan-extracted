use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WiringPi::API',
    VERSION_FROM      => 'lib/WiringPi/API.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WiringPi/API.pm',
       AUTHOR         => 'Steve Bertrand <steveb@cpan.org>') : ()),
    LIBS              => ['-lwiringPi -lwiringPiDev -lrt'],
    DEFINE            => '',
    INC               => '-I.',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/wiringpi-api/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/wiringpi-api.git',
                web => 'https://github.com/stevieb9/wiringpi-api',
            },
        },
    },
    MIN_PERL_VERSION  => 5.006,
    LICENSE           => 'perl_5',
    PREREQ_PM         => {
    },
);
