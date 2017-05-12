#!perl
use strict;
use warnings;
use Module::Build 0.4004;


my $builder = Module::Build->new(
    module_name         => 'XMLRPC::Fast',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/XMLRPC/Fast.pm',

    requires => {
        perl            => '5.010000',
        'B'             => 0,
        'Encode'        => 0,
        'Exporter'      => 0,
        'MIME::Base64'  => 0,
        'XML::Parser'   => 0,
    },
    test_requires => {
        'Data::Dumper'  => 0,
        'Storable'      => 0,
        'Test::More'    => '0.45',
    },
    test_recommends => {
        'Test::LongString'  => 0,
    },
    meta_merge => {
        resources       => {
            repository  => "https://github.com/maddingue/XMLRPC-Fast.git",
        }
    },
    add_to_cleanup      => [ 'XMLRPC-Fast-*' ],
);

$builder->create_build_script();

