use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WebService::LastFM',
    VERSION_FROM      => 'lib/WebService/LastFM.pm',
    PREREQ_PM         => {
        LWP             => 0,
        Digest::MD5     => 0,
        Class::Accessor => 0,
        XML::Simple     => 0,
    }
);
