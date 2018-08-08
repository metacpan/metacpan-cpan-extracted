use 5.026000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WebService::Hexonet::Connector',
    VERSION_FROM => 'lib/WebService/Hexonet/Connector.pm',
    PREREQ_PM    => {
        'LWP::Protocol::https' => 6.07,
        'LWP::UserAgent' => 6.35,
        'Time::Local'    => 0,
        'MIME::Base64'   => 0,
        'Data::Dumper'   => 2.161
    },
    TEST_REQUIRES => {
        'Test::More'             => 0,
        'Test::Exception'        => 0.43,
        'Test::RequiresInternet' => 0.05,
        'Scalar::Util'           => 0
    },
    ABSTRACT_FROM => 'lib/WebService/Hexonet/Connector.pm',
    AUTHOR        => 'hexonet <middleware@hexonet.net>',
    LICENSE       => 'mit'
);
