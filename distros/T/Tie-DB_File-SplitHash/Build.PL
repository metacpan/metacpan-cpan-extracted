use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Tie::DB_File::SplitHash',
        dist_author    => 'Benjamin Franz <snowhare@nihongo.org>',
        dist_abstract  => 'Transparently divides a DB_File hash into multiple smaller files',
        license        => 'perl',
        requires       => {
            'Carp'         => 0,
            'Digest::SHA1' => 0,
            'File::Spec'   => 0,
            'File::Path'   => 0,
            'File::Temp'   => 0,
            'Fcntl'        => 0,
            'DB_File'      => 0,
        },
        build_requires => { },
      )->create_build_script;
