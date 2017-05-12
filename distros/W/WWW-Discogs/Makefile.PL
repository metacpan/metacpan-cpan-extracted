use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'WWW::Discogs',
    VERSION_FROM => 'lib/WWW/Discogs.pm',
    ABSTRACT_FROM => 'lib/WWW/Discogs.pm',
    AUTHOR => 'Michal Gasek <michal@gasek.eu>',
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.008',
    PREREQ_PM => {
        'LWP::UserAgent' => 0,
        'URI' => 0,
        'URI::Escape' => 0,
        'JSON::XS' => 0,
        'NEXT' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Deep' => 0,
        'Test::Exception' => 0,
        'File::Slurp' => 0,
        'HTTP::Response' => 0,
        'Test::Mock::LWP::Dispatch' => "0.03",
    },
);
