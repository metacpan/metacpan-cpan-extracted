use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'WebService::Hatena::Exist',
    VERSION_FROM      => 'lib/WebService/Hatena/Exist.pm',
    PREREQ_PM         => {
        'Test::More'              => '0.47',
        'Class::ErrorHandler'     => 0,
        'URI::Fetch::SimpleCache' => 0,
        'XML::Simple'             => 0,
        'Readonly'                => 0,
    },
);
