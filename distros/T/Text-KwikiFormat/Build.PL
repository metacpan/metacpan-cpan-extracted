use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::KwikiFormat',
    license             => 'perl',
    dist_author         => q{Ruey-Cheng Chen <rueycheng@gmail.com>},
    dist_version_from   => 'lib/Text/KwikiFormat.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
	'Kwiki' => 0.39,
    },
    add_to_cleanup      => [ 'Text-KwikiFormat-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
