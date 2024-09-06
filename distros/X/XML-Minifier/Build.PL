use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'XML::Minifier',
    license             => 'artistic_2',
    dist_author         => q{Thibault DUPONCHELLE <thibault.duponchelle@gmail.com>},
    dist_version_from   => 'lib/XML/Minifier.pm',
    release_status      => 'stable',
    script_files        => [ 'script/xml-minifier' ],
    configure_requires  => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More'    => '0',
        'Test::Slow'    => '0.04'
    },
    build_requires => {
        'XML::LibXML'   => '0',
        #'Foo::Bar::Module' => '5.0401',
    },
    add_to_cleanup      => [ 'XML-Minifier-*' ],
);

$builder->create_build_script();

