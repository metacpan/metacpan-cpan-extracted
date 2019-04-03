use 5.026_000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WebService::Hexonet::Connector',
    VERSION_FROM => 'lib/WebService/Hexonet/Connector.pm',
    PREREQ_PM    => {
        'LWP::Protocol::https' => 6.07,
        'LWP::UserAgent'       => 6.35,
        'Time::Local'          => 0,
        'MIME::Base64'         => 0,
        'Data::Dumper'         => 2.161,
        'utf8'                 => 0,
        'Readonly'             => 2.05,
        'Carp'                 => 0,
        'POSIX'                => 0,
        'List::MoreUtils'      => 0.416,
        'version'              => 0.9917,
        'Config'               => 0
    },
    TEST_REQUIRES => {
        'Perl::Critic'           => 1.132,
        'CPAN::Uploader'         => 0.103013,
        'Devel::Cover'           => 1.30,
        'Test::More'             => 0,
        'Test::Exception'        => 0.43,
        'Test::RequiresInternet' => 0.05,
        'Scalar::Util'           => 0,
        'Readonly'               => 2.05,
        'version'                => 0.9917,
        'POSIX'                  => 0,
        'Config'                 => 0
    },
    ABSTRACT_FROM    => 'lib/WebService/Hexonet/Connector.pm',
    AUTHOR           => 'hexonet <middleware@hexonet.net>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.026000'
);

1;
