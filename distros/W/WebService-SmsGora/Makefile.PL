use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WebService::SmsGora',
    AUTHOR           => 'Tekservix <support@tekservix.com>',
    VERSION_FROM     => 'lib/WebService/SmsGora.pm',
    ABSTRACT_FROM    => 'lib/WebService/SmsGora.pm',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {
        'Carp'            => 0,
        'Digest::SHA'     => 0,
        'HTTP::Tiny'      => '0.014',
        'IO::Socket::SSL' => '1.42',
        'JSON::PP'        => 0,
        'Net::SSLeay'     => '1.49',
    },
    TEST_REQUIRES => { 'Test::More' => '0.88' },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://tekservix.com/smsgora/',
            repository => {
                type => 'git',
                url  => 'https://github.com/TekservixHQ/smsgora-perl.git',
                web  => 'https://github.com/TekservixHQ/smsgora-perl',
            },
            bugtracker => { web => 'https://github.com/TekservixHQ/smsgora-perl/issues' },
        },
        keywords => [qw(sms sms-gateway sms-api-gateway bulk-sms android tekservix)],
    },
);
