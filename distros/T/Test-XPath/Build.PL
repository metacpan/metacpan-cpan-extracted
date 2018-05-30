use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'Test::XPath',
    license            => 'perl',
    configure_requires => { 'Module::Build' => '0.30', },
    build_requires     => {
        'Module::Build' => '0.30',
        'Test::More'    => '0.70',
    },
    requires => {
        'Test::Builder' => '0.70',
        'XML::LibXML'   => '1.70',
        'perl'          => 5.006002,
    },
    recommends => {
        'Test::Pod'             => '1.41',
        'Test::Pod::Coverage'   => '1.06',
        'HTML::Selector::XPath' => '0.06',
    },
    meta_merge => {
        resources => {
            homepage   => 'https://metacpan.org/pod/Test::XPath',
            bugtracker => 'http://github.com/manwar/test-xpath/issues/',
            repository => 'http://github.com/manwar/test-xpath',
        }
    },
)->create_build_script;
