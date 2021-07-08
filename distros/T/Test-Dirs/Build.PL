use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Test::Dirs',
    license           => 'perl',
    dist_author       => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from => 'lib/Test/Dirs.pm',
    
    build_requires => {
        'Test::More'   => 0,
        'Test::Tester' => 0,
        'File::is'     => 0,
    },
    configure_requires => {
        'Module::Build' => '0.3607',
    },
    requires => {
        'File::Temp'       => 0.19,    # tempdir() added
        'File::DirCompare' => 0,
        'Test::Builder'    => 0,
        'File::Copy::Recursive' => 0,
        'Carp'             => 0,
        'File::DirCompare' => 0,
        'List::MoreUtils'  => 0,
        'Text::Diff'       => 0,
        'Path::Class'      => 0,
        'File::Path'       => 2.07,    # remove_tree() added
    },
    script_files => [
    ],
    add_to_cleanup => [ 'Test-Dirs-*' ],
    create_readme  => 1,
    meta_merge => {
        resources => {
            repository => 'https://github.com/jozef/Test-Dirs/',
            bugtracker => 'https://github.com/jozef/Test-Dirs/issues',
        },
        keywords => [ qw/ test dir folder / ],
    },
);

$builder->create_build_script();
