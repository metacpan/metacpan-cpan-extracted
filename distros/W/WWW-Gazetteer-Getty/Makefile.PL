use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => "WWW::Gazetteer::Getty",
    ABSTRACT     => 'Find location of world towns and cities',
    VERSION_FROM => 'Getty.pm',
    PREREQ_PM    => {
        'LWP::UserAgent' => 0.01,
        'Test::Simple'   => 0.01,
        'WWW::Gazetteer' => '0.20',
    },
    AUTHOR  => 'Leon Brocard <acme@astray.com>',
    LICENSE => 'perl',
);

