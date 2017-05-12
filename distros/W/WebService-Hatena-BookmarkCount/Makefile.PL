use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService-Hatena-BookmarkCount',
    VERSION_FROM        => 'lib/WebService/Hatena/BookmarkCount.pm',
    PREREQ_PM           => {
        'Test::More'        => '0',
        'XML::TreePP'       => '0.18',
#       'LWP::UserAgent'    => '0',
#       'HTTP::Lite'        => '0',
    },
);
