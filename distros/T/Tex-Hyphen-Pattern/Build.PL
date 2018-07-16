use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name => 'Tex::Hyphen::Pattern',
    license     => 'perl',
    dist_author => 'Roland van Ipenburg <ipenburg@xs4all.nl>',
    requires    => {
        'perl'              => '5.14.0',
        'Moose'             => 0,
        'Encode'            => 0,
        'File::Temp'        => 0,
        'Log::Log4perl'     => 0,
        'Module::Pluggable' => 0,
        'Readonly'          => 0,
        'Set::Scalar'       => 0,
        'Test::More'        => 0.81,
        'Test::NoWarnings'  => 0,
        'version'           => 0,
    },
    build_requires => { 'Test::More' => 0.81, },
    script_files   => [ qw(tools/build_catalog.pl tools/build_catalog_from_ctan.pl), ],
    sign           => 1,
    meta_merge     => {
        resources => {
            repository => 'https://github.com/ipenburg/TeX-Hyphen-Pattern'
        }
    },
)->create_build_script;
