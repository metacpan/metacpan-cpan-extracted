use strict;
 
use Module::Build;
 
my $build = Module::Build->new
      ( module_name    => 'Tie::DB_File::SplitHash',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'Transparently divides a DB_File hash into multiple smaller files',
        license        => 'mit',
        requires       => {
            'perl'         => '5.006',
            'warnings'     => 0,
            'Carp'         => 0,
            'DB_File'      => 0,
            'Digest::SHA1' => 0,
            'Fcntl'        => 0,
            'File::Spec'   => 0,
            'File::Path'   => 0,
        },
        build_requires => { },
        test_requires => {
            'perl'         => '5.006',
            'warnings'     => 0,
            'Carp'         => 0,
            'DB_File'      => 0,
            'Digest::SHA1' => 0,
            'Fcntl'        => 0,
            'File::Spec'   => 0,
            'File::Path'   => 0,
            'File::Temp'   => 0,
            'Test::More'   => 0,
        },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-Tie-DB_File-SplitHash/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-Tie-DB_File-SplitHash',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-Tie-DB_File-SplitHash.git',
                   web  => 'https://github.com/JerilynFranz/perl-Tie-DB_File-SplitHash',
               },
            },
        },
      )->create_build_script;


