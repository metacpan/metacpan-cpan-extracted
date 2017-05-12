use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::NoMalware',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Test/NoMalware.pm',
    configure_requires  => { 'Module::Build' => 0.38 },
    requires => {
        'Test::More'      => 0,
    },
    build_requires => {
        'Test::More'      => 0,
    },
    add_to_cleanup      => [ 'Test-NoMalware-*' ],
    create_readme       => 1,
    meta_merge => {
        resources => {
            repository => 'https://github.com/jozef/Test-NoMalware',
            bugtracker => 'http://github.com/jozef/Test-NoMalware/issues',
        },
    },
);

$builder->create_build_script();
