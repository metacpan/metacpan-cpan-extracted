use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Tie::ListKeyedHash',
        dist_author    => 'Benjamin Franz <snowhare@nihongo.org>',
        dist_abstract  => 'A system allowing the use of anonymous arrays as keys to a hash.',
        license        => 'perl',
        requires       => {
            'Test::More'    => 0,
            },
        build_requires => { },
      )->create_build_script;
