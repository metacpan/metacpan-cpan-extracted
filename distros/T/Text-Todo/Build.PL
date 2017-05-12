use strict;
use warnings;
use Module::Build;

# $AFresh1: Build.PL,v 1.9 2010/01/22 18:15:56 andrew Exp $

my $builder = Module::Build->new(
    module_name       => 'Text::Todo',
    license           => 'perl',
    dist_author       => 'Andrew Fresh <andrew@cpan.org>',
    dist_version_from => 'lib/Text/Todo.pm',
    requires          => {
        'Carp'              => 0,
        'Class::Std::Utils' => 0,
        'File::Spec'        => 0,
        'version'           => 0,
    },
    build_requires     => {
        'Test::More'        => 0.82,
    },
    add_to_cleanup     => [
        'Text-Todo-*',
        'MANIFEST',
        'META.yml',
        'Makefile.PL',
        'LICENSE',
        'README',
    ],
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    meta_merge     => {
        resources => {
            repository  => 'https://github.com/afresh1/Text-Todo'
        }
    },
);

$builder->create_build_script();
