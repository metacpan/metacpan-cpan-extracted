use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'WebService::Wikimapia',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/WebService/Wikimapia.pm',
    ABSTRACT_FROM      => 'lib/WebService/Wikimapia.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'JSON'                 => 0,
        'Moo'                  => 0,
        'namespace::autoclean' => '0.28',
        'Throwable'            => 0,
        'HTTP::Tiny'           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WebService-Wikimapia-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'WebService::Wikimapia'                       => { file => 'lib/WebService/Wikimapia.pm'                    , version => '0.14' },
            'WebService::Wikimapia::Params'               => { file => 'lib/WebService/Wikimapia/Params.pm'             , version => '0.14' },
            'WebService::Wikimapia::Place'                => { file => 'lib/WebService/Wikimapia/Place.pm'              , version => '0.14' },
            'WebService::Wikimapia::City'                 => { file => 'lib/WebService/Wikimapia/City.pm'               , version => '0.14' },
            'WebService::Wikimapia::Street'               => { file => 'lib/WebService/Wikimapia/Street.pm'             , version => '0.14' },
            'WebService::Wikimapia::Hotel'                => { file => 'lib/WebService/Wikimapia/Hotel.pm'              , version => '0.14' },
            'WebService::Wikimapia::Comment'              => { file => 'lib/WebService/Wikimapia/Comment.pm'            , version => '0.14' },
            'WebService::Wikimapia::Photo'                => { file => 'lib/WebService/Wikimapia/Photo.pm'              , version => '0.14' },
            'WebService::Wikimapia::Language'             => { file => 'lib/WebService/Wikimapia/Language.pm'           , version => '0.14' },
            'WebService::Wikimapia::User'                 => { file => 'lib/WebService/Wikimapia/User.pm'               , version => '0.14' },
            'WebService::Wikimapia::GlobalAdmin'          => { file => 'lib/WebService/Wikimapia/GlobalAdmin.pm'        , version => '0.14' },
            'WebService::Wikimapia::Category'             => { file => 'lib/WebService/Wikimapia/Category.pm'           , version => '0.14' },
            'WebService::Wikimapia::Category::Synonym'    => { file => 'lib/WebService/Wikimapia/Category/Synonym.pm'   , version => '0.14' },
            'WebService::Wikimapia::Polygon'              => { file => 'lib/WebService/Wikimapia/Polygon.pm'            , version => '0.14' },
            'WebService::Wikimapia::Tag'                  => { file => 'lib/WebService/Wikimapia/Tag.pm'                , version => '0.14' },
            'WebService::Wikimapia::Object'               => { file => 'lib/WebService/Wikimapia/Object.pm'             , version => '0.14' },
            'WebService::Wikimapia::Location'             => { file => 'lib/WebService/Wikimapia/Location.pm'           , version => '0.14' },
            'WebService::Wikimapia::UserAgent'            => { file => 'lib/WebService/Wikimapia/UserAgent.pm'          , version => '0.14' },
            'WebService::Wikimapia::UserAgent::Exception' => { file => 'lib/WebService/Wikimapia/UserAgent/Exception.pm', version => '0.14' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/WebService-Wikimapia.git',
                web  => 'https://github.com/manwar/WebService-Wikimapia',
            },
        }})
     : ()
    ),
);
