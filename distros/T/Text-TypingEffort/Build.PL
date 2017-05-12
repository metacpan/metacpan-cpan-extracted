use Module::Build;

# See perldoc Module::Build for details of how this works

my $build = Module::Build->new(
    module_name    => 'Text::TypingEffort',
    license        => 'mit',
    build_requires => {
        'Test::More' => 0.31,
        'File::Temp' => 0.14,    # we need the OO interface
    },
    script_files       => [ 'scripts/effort.pl', ],
    create_makefile_pl => 'traditional',
    meta_merge         => {
        resources => {
            repository => 'git://git.ndrix.com/Text-TypingEffort',
            homepage   => 'http://git.ndrix.com/?p=Text-TypingEffort;a=summary',
            bugtracker =>
              'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-TypingEffort',
        },
    },
);

$build->create_build_script;
