#!perl
use strict;
use warnings;
use Module::Build;
use Module::Build::Compat;

my $builder = Module::Build->new(
    module_name          => 'XML::API',
    dist_abstract        => 'Perl extension for writing XML',
    dist_author          => 'Mark Lawrence <nomad@null.net>',
    dist_version         => '0.30',
    create_license       => 1,
    create_readme        => 1,
    license              => 'GPL_3',
    recursive_test_files => 1,
    add_to_cleanup       => ['XML-API-*'],
    create_makefile_pl   => 'small',
    configure_requires   => {
        'Module::Build' => '0.4004',
    },
    requires => {
        'XML::SAX'         => 0,
        'XML::LibXML::SAX' => 0,
        'Scalar::Util'     => 0,
    },
    test_requires => {
        'Test::More'          => 0,
        'Test::Exception'     => 0,
        'Test::Memory::Cycle' => 0,
        'File::Slurp'         => 0,
    },
    no_index => {
        package => [ 'XML::API::Element', 'XML::API::SAXHandler', ],
    },
    meta_merge => {
        resources => {
            homepage => 'https://github.com/mlawren/xml-api',
            bugtracker =>
              'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-API',
            repository => 'git://github.com/mlawren/xml-api.git',
        },
        keywords => [],
    },
);

$builder->create_build_script();

# I prefer to use make when developing so lets built the Makefile here
# as well
Module::Build::Compat->write_makefile( build_class => 'Module::Build' );
