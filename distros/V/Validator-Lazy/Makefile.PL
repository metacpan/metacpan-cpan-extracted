use 5.14.0;
use strict;
use warnings;
use inc::Module::Install;

name     'Validator-Lazy';
all_from 'lib/Validator/Lazy.pm';
author   q{ANTONC <antonc@cpan.org>};
license  'artistic2';

perl_version '5.14.0';

tests_recursive('t');

resources (
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator-Lazy',
);

configure_requires (
    'Module::Install'      => 0,
    'Modern::Perl'         => 0,
    'ExtUtils::MakeMaker'  => 0,
);

build_requires (
    'Modern::Perl'         => 0,
    'YAML::XS'             => 0,

    'Moose'                => 0,
    'Moose::Role'          => 0,
    'Moose::Util'          => 0,

    'Email::Valid'         => 0,
    'Locale::Codes'        => 0,
    'Net::IP'              => 0,
    'Net::Domain::TLD'     => 0,
    'Number::Phone'        => 0,

    'ExtUtils::Installed'  => 0,
    'Test::More'           => 0,
    'Test::Spec'           => 0,
    'Pod::Coverage'        => 0,
    'Test::CheckManifest'  => 0,
    'Test::Exception'      => 0,
    'Test::Pod::Coverage'  => 0,
    'Test::Pod'            => 0,
    'Module::Metadata'     => '1.000009',
);

requires (
    'Modern::Perl'         => 0,
    'YAML::XS'             => 0,

    'Moose'                => 0,
    'Moose::Role'          => 0,
    'Moose::Util'          => 0,

    'Email::Valid'         => 0,
    'Locale::Codes'        => '3.50',
    'Net::IP'              => 0,
    'Net::Domain::TLD'     => 0,
    'Number::Phone'        => 0,
);

install_as_cpan;
auto_install;
WriteAll;
