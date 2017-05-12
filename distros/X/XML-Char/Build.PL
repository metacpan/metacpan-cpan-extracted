use strict;
use warnings;
use Module::Build;
use File::Spec;

my $builder = Module::Build->new(
    module_name         => 'XML::Char',
    license             => 'perl',
    dist_author         => q{Jozef Kutej <jkutej@cpan.org>},
    dist_version_from   => 'lib/XML/Char.pm',
    configure_requires  => { 'Module::Build' => 0.42 },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [
    	'XML-Char-*',
    	File::Spec->catfile('lib', 'XML', 'Char.c'),
    	File::Spec->catfile('lib', 'XML', 'Char.o')
    ],
    create_readme       => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/XML-Char.git',
            bugtracker => 'http://github.com/jozef/XML-Char/issues',
        },
        keywords => [ qw/ xml characters utf8 utf-8 valid invalid / ],
    },
);

$builder->create_build_script();
