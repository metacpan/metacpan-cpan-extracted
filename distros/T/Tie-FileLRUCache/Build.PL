use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Tie::FileLRUCache',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'A lightweight but robust filesystem based persistent LRU cache',
        license        => 'mit',
        requires       => {
            'perl'              => '5.006',
            'warnings'          => 0,
            'Carp'              => 0,
            'File::Temp'        => 0,
            'Digest::SHA1'      => 0,
            'Storable'          => 0,
            'Class::ParmList'   => '1.03',
            },
        build_requires => { },
        test_requires       => {
            'perl'              => '5.006',
            'warnings'          => 0,
            'Carp'              => 0,
            'File::Temp'        => 0,
            'Test::More'        => 0,
            'Digest::SHA1'      => 0,
            'Storable'          => 0,
            'Class::ParmList'   => '1.03',
            },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-Tie-FileLRUCache/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-Tie-FileLRUCache',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-Tie-FileLRUCache.git',
                   web  => 'https://github.com/JerilynFranz/perl-Tie-FileLRUCache',
               },
            },
        },
      )->create_build_script;