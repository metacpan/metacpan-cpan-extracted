use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Text::Diff::HTML',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => { 'Test::Pod'     => '1.41'   },
    build_requires     => {
        'Test::More'    => '0.17',
        'Module::Build' => '0.2701',
    },
    requires           => {
        Text::Diff     => '0.11',
        HTML::Entities => '0',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Text-Diff-HTML/',
            bugtracker => 'http://github.com/theory/text-diff-html/issues/',
            repository => 'http://github.com/theory/text-diff-html/',
        }
    },
);
$build->create_build_script;
