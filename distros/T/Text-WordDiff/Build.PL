use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Text::WordDiff',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => { 'Test::Pod'     => '1.41'   },
    requires           => {
        Algorithm::Diff => '1.19',
        Term::ANSIColor => '0',
        HTML::Entities  => '0',
    },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
        'File::Spec'    => '0',
    },
    meta_merge => {
        resources => {
            homepage   => 'https://metacpan.org/release/Text-WordDiff',
            bugtracker => 'https://github.com/ThePerlShop/text-worddiff/issues',
            repository => 'https://github.com/ThePerlShop/text-worddiff',
        }
    },
);
$build->create_build_script;
