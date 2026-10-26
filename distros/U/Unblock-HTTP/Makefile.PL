use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Unblock::HTTP',
    VERSION_FROM     => 'lib/Unblock/HTTP.pm',
    ABSTRACT_FROM    => 'lib/Unblock/HTTP.pm',
    AUTHOR           => 'Joshua S. Day <HAX@cpan.org>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.020',
    PREREQ_PM => {
        'Carp'             => 0,
        'parent'           => 0,
        'URI'              => 0,
        'Unblock::HTTP1'   => '0.13',
        'Uniform::HTTP'   => '0.06',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'CPAN::Meta' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        optional_features => {
            http2 => {
                description => 'HTTP/2 protocol support',
                prereqs => { runtime => { requires => { 'Unblock::HTTP2' => '0.13' } } },
            },
            http3 => {
                description => 'HTTP/3 protocol support',
                prereqs => { runtime => { requires => { 'Unblock::HTTP3' => '0.14' } } },
            },
        },
        no_index => {
            package => [qw(
                Unblock::HTTP::_AltSvc
                Unblock::HTTP::_ClientOperation
                Unblock::HTTP::_EngineFactory
                Unblock::HTTP::_Policy
                Unblock::HTTP::_Session
                Unblock::HTTP::_WebSocketH2Body
            )],
        },
        resources => {
            homepage => 'https://github.com/haxmeister/perl-Unblock-HTTP',
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-Unblock-HTTP.git',
                web  => 'https://github.com/haxmeister/perl-Unblock-HTTP',
            },
            bugtracker => {
                web => 'https://github.com/haxmeister/perl-Unblock-HTTP/issues',
            },
        },
    },
);
