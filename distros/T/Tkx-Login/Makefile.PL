use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "A Tkx based Login screen",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'Tkx-Login',
  VERSION  => '1.11',

  PREREQ_PM => {
          'Test::More' => 0,
          'Tkx' => 0
        },

  ( $ExtUtils::MakeMaker::VERSION < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                no_index => {directory => [qw/t/]},
                provides => 

	{
          'Tkx::Login' => {
                            'version' => '1.11',
                            'file' => 'lib/Tkx/Login.pm'
                          }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-Tkx-Login.git',
                        web  => 'http://github.com/bennie/perl-Tkx-Login',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=Tkx-Login',
                    },

                },
            },
        )
    ),

  ( $ExtUtils::MakeMaker::VERSION < 6.48
        ? ()
        : ( MIN_PERL_VERSION => '5.006' )
  )

);