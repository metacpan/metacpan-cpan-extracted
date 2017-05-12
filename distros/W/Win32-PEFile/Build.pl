use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Win32::PEFile',
    license           => 'perl',
    dist_author       => q{Peter Jaquiery <grandpa@cpan.org>},
    dist_version_from => 'lib/Win32/PEFile.pm',
    build_requires    => {
        'Test::More' => 0,
        perl         => '5.8.8',
    },
    add_to_cleanup     => ['Win32-PEFile-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
