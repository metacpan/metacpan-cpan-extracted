use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::ASCIITable::TW',
    license             => 'perl',
    dist_author         => 'Alec Chen <alec@cpan.org>',
    dist_version_from   => 'lib/Text/ASCIITable/TW.pm',
    configure_requires => { 'Module::Build' => 0.38 },
    build_requires => {
        'Test::More'       => 0,
        'Moose'            => 0.55,
        'version'          => 0.76,
        'Encode'           => 2.26,
        'Text::ASCIITable' => 0.18,
    },
    add_to_cleanup      => [ 'Text-ASCIITable-TW-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
