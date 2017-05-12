use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::CheckHTML',
    AUTHOR           => q{David Farrell <sillymoos@cpan.org>},
    VERSION_FROM     => 'lib/WWW/CheckHTML.pm',
    ABSTRACT_FROM    => 'lib/WWW/CheckHTML.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'HTTP::Tiny'                    => 0.034,
        'Method::Signatures'            => 0,
        'Time::Piece'                   => 0,
        'YAML::XS'                      => 0.41,
        Carp                            => 1.26,
        'Email::Sender::Simple'         => 1.300006,
        'Email::Simple'                 => 2.201,
        'Email::Simple::Creator'        => 0,
        'Email::Sender::Transport::SMTP'=> 0,
        'MIME::Base64'                  => 0,
        'Authen::SASL'                  => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-CheckHTML-*' },
);
