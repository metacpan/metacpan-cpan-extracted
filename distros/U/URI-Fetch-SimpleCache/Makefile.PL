use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'URI::Fetch::SimpleCache',
    VERSION_FROM      => 'lib/URI/Fetch/SimpleCache.pm',
    PREREQ_PM         => {
        'URI::Fetch'       => 0,
        'Cache::FileCache' => 0,
    },
);
