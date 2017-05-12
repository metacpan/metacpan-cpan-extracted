use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Widget::Meta',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => { 'Test::Pod'     => '1.41'   },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Widget-Meta/',
            bugtracker => 'http://github.com/theory/widget-meta/issues/',
            repository => 'http://github.com/theory/widget-meta/',
        }
    },
);
$build->create_build_script;
