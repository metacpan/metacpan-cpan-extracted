use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Tie::FileLRUCache',
        dist_author    => 'Benjamin Franz <snowhare@nihongo.org>',
        dist_abstract  => 'A lightweight but robust filesystem based persistent LRU cache',
        license        => 'perl',
        requires       => {
            'File::Temp'        => 0,
            'Test::More'        => 0,
            'Digest::SHA1'      => 0,
            'Storable'          => 0,
            'Class::ParmList'   => '1.03',
            },
        build_requires => { },
      )->create_build_script;

