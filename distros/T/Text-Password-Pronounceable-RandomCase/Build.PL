use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Text::Password::Pronounceable::RandomCase',
    license           => 'perl',
    dist_version_from => 'lib/Text/Password/Pronounceable/RandomCase.pm',
    requires          => {
        'parent'                        => 0,
        'Text::Password::Pronounceable' => 0,
        'Readonly'                      => 0,
    },
    build_requires     => { 'Test::More' => 0, },
    add_to_cleanup     => ['Text::Password-Pronounceable-RandomCase-*'],
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    meta_merge         => {
        resources => {
            repository =>
              'http://github.com/mdom/text-password-pronounceable-randomcase',
        },
    },

);

$builder->create_build_script();
