use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Time::Piece::ISO',
    license            => 'perl',
    requires           => { Time::Piece     => '1.01'   },
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => { 'Test::Pod'     => '1.41'   },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
    },
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Time-Piece-ISO/',
            bugtracker => 'http://github.com/theory/time-piece-iso/issues/',
            repository => 'http://github.com/theory/time-piece-iso/',
        }
    },
);
$build->create_build_script;
