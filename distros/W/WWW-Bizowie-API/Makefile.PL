use 5.008006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::Bizowie::API',
    VERSION_FROM     => 'lib/WWW/Bizowie/API.pm',
    ABSTRACT_FROM    => 'lib/WWW/Bizowie/API.pm',
    AUTHOR           => 'Bizowie <info@bizowie.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.008006',
    PREREQ_PM        => {
        'LWP::UserAgent'        => 0,
        'HTTP::Request::Common' => 0,
        'Try::Tiny'             => 0,
        'JSON'                  => 0,
        'Mo'                    => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://bizowie.com',
            repository => {
                type => 'git',
                url  => 'https://github.com/bizowie/WWW-Bizowie-API.git',
                web  => 'https://github.com/bizowie/WWW-Bizowie-API',
            },
            bugtracker => {
                web => 'https://github.com/bizowie/WWW-Bizowie-API/issues',
            },
        },
        keywords => [
            'erp', 'cloud-erp', 'distribution', 'wholesale',
            'manufacturing', 'bizowie', 'api', 'sdk',
        ],
    },
);

