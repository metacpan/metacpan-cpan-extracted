use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name    => 'Text::Emoticon::Unicode',
    license        => 'perl',
    create_license => 1,
    create_readme  => 1,
    configure_requires => {
        'Module::Build' => 0.36,
    },
    build_requires => {
        'Test::More' => 0.41,  # diag()
    },
    requires => {
        'perl'           => '5.6.0',  # our()
        'parent'         => 0,
        'Text::Emoticon' => 0,
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/text-emoticon-unicode-pm5.git',
            homepage   => 'https://github.com/patch/text-emoticon-unicode-pm5',
            bugtracker => 'https://github.com/patch/text-emoticon-unicode-pm5/issues',
        },
    },
);

$builder->create_build_script;
