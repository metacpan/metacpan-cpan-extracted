use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'WWW::Google::PageSpeedOnline',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/WWW/Google/PageSpeedOnline.pm',
    ABSTRACT_FROM      => 'lib/WWW/Google/PageSpeedOnline.pm',
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
        'WWW::Google::UserAgent' => '0.23',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Google-PageSpeedOnline-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'WWW::Google::PageSpeedOnline'               => { file => 'lib/WWW/Google/PageSpeedOnline.pm'            , version => '0.29' },
            'WWW::Google::PageSpeedOnline::Params'       => { file => 'lib/WWW/Google/PageSpeedOnline/Params.pm'     , version => '0.29' },
            'WWW::Google::PageSpeedOnline::Advise'       => { file => 'lib/WWW/Google/PageSpeedOnline/Advise.pm'     , version => '0.29' },
            'WWW::Google::PageSpeedOnline::Stats'        => { file => 'lib/WWW/Google/PageSpeedOnline/Stats.pm'      , version => '0.29' },
            'WWW::Google::PageSpeedOnline::Result'       => { file => 'lib/WWW/Google/PageSpeedOnline/Result.pm'     , version => '0.29' },
            'WWW::Google::PageSpeedOnline::Result::Rule' => { file => 'lib/WWW/Google/PageSpeedOnline/Result/Rule.pm', version => '0.29' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/WWW-Google-PageSpeedOnline.git',
                web  => 'https://github.com/manwar/WWW-Google-PageSpeedOnline',
            },
        }})
     : ()
    ),
);
