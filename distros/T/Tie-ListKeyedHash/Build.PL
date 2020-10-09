use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'Tie::ListKeyedHash',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'A system allowing the use of anonymous arrays as keys to a hash.',
        license        => 'mit',
        requires       => {
            'perl'              => '5.006',
            'warnings'          => 0,
            'Carp'              => 0,
            },
        build_requires => { },
        test_requires       => {
            'perl'              => '5.006',
            'warnings'          => 0,
            'Carp'              => 0,
            'Test::More'        => 0,
            },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-Tie-ListKeyedHash/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-Tie-ListKeyedHash',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-Tie-ListKeyedHash.git',
                   web  => 'https://github.com/JerilynFranz/perl-Tie-ListKeyedHash',
               },
            },
        },
      )->create_build_script;
