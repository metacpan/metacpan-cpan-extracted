use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WWW::Alexa::TrafficRank',
    AUTHOR       => 'AppAgg <guruperl@cpan.org>',
    VERSION_FROM => 'lib/WWW/Alexa/TrafficRank.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES     => {},
    PREREQ_PM    => { 'LWP::UserAgent' => 0 },
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    clean        => { FILES => 'WWW-Alexa-TrafficRank-*' },
);
