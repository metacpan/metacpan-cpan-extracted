use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::WAservix',
    AUTHOR           => 'Tekservix <support@tekservix.com>',
    VERSION_FROM     => 'lib/WebService/WAservix.pm',
    ABSTRACT_FROM    => 'lib/WebService/WAservix.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {
        'Carp'            => 0,
        'HTTP::Tiny'      => '0.014',
        'IO::Socket::SSL' => '1.42',
        'JSON::PP'        => 0,
        'Net::SSLeay'     => '1.49',
    },
    TEST_REQUIRES => { 'Test::More' => '0.88' },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://tekservix.com/waservix/',
            repository => {
                type => 'git',
                url  => 'https://github.com/TekservixHQ/waservix-perl.git',
                web  => 'https://github.com/TekservixHQ/waservix-perl',
            },
            bugtracker => { web => 'https://github.com/TekservixHQ/waservix-perl/issues' },
        },
        keywords => [qw(whatsapp whatsapp-api messaging tekservix)],
    },
);
