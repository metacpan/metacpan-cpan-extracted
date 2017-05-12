use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'TomTom::WEBFLEET::Connect',
    VERSION_FROM      => 'lib/TomTom/WEBFLEET/Connect.pm',
    PREREQ_PM         => {
        LWP::UserAgent => 0,
        Text::ParseWords => 0
    },
    ABSTRACT_FROM  => 'lib/TomTom/WEBFLEET/Connect.pm',
    AUTHOR         => 'Ingo Miosga <ingo.miosga@tomtom.com>',
);
