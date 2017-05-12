use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'VendorAPI::2Checkout::Client',
    AUTHOR              => q{Len Jaffe <lenjaffe@jaffesystems.com>},
    VERSION_FROM        => 'lib/VendorAPI/2Checkout/Client.pm',
    ABSTRACT_FROM       => 'lib/VendorAPI/2Checkout/Client.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'LWP::UserAgent'   => 0,
        'Params::Validate' => 0,
        'URI'              => 0,
        'URI::QueryParam'  => 0,
        'Moose'            => 0,
        'MooseX::NonMoose' => 0,
        'Moose::Util::TypeConstraints'  => 0,
        'namespace::autoclean'          => 0,
        'UNIVERSAL::require'            => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'      => 0.87,
        'XML::Simple'     => 0,
        'JSON::Any'       => 0,
        'List::MoreUtils' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'VendorAPI-2Checkout-Client-*' },
);
