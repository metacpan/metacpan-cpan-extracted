use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'WWW::Google::APIDiscovery',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/WWW/Google/APIDiscovery.pm',
    ABSTRACT_FROM      => 'lib/WWW/Google/APIDiscovery.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => '1.001014',
    },
    PREREQ_PM => {
        'Moo'                    => '2.000000',
        'namespace::autoclean'   => '0.28',
        'JSON'                   => '2.53',
        'WWW::Google::UserAgent' => '0.22'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Google-APIDiscovery-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'WWW::Google::APIDiscovery'                => { file => 'lib/WWW/Google/APIDiscovery.pm'             , version => '0.27' },
            'WWW::Google::APIDiscovery::API'           => { file => 'lib/WWW/Google/APIDiscovery/API.pm'         , version => '0.27' },
            'WWW::Google::APIDiscovery::API::MetaData' => { file => 'lib/WWW/Google/APIDiscovery/API/MetaData.pm', version => '0.27' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/WWW-Google-APIDiscovery.git',
                web  => 'https://github.com/manwar/WWW-Google-APIDiscovery',
            },
        }})
     : ()
    ),
);
