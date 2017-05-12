use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name              => 'XML::Parser::Style::IxTree',
    license                  => 'perl',
    dist_author              => 'Igor Afanasyev <igor.afanasyev@gmail.com>',
    dist_version_from        => 'lib/XML/Parser/Style/IxTree.pm',
    release_status           => 'stable',
    configure_requires => {
        'Module::Build'      => 0,
    },
    requires => {
        'Tie::IxHash'        => '1.22',
        'XML::Parser::Style::Tree' => 0,
    },
    add_to_cleanup           => ['XML-Parser-*', 'Makefile.PL', 'MYMETA.*', 'META.*'],
    create_makefile_pl       => 'traditional',
);

$builder->create_build_script();
