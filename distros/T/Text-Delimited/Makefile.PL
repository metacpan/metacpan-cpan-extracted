use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "Delimited Text Processing",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'Text::Delimited',
  VERSION  => '2.12',

  PREREQ_PM => {
          'Test::Simple' => '0',
          'Test::More' => 0,
          'Symbol' => 0
        },

  ( $ExtUtils::MakeMaker::VERSION < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                no_index => {directory => [qw/t/]},
                provides => 

	{
          'Text::Delimited' => {
                                 'file' => 'lib/Text/Delimited.pm',
                                 'version' => '2.12'
                               }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-Text-Delimited.git',
                        web  => 'http://github.com/bennie/perl-Text-Delimited',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=Text-Delimited',
                    },

                },
            },
        )
    ),

  ( $ExtUtils::MakeMaker::VERSION < 6.48
        ? ()
        : ( MIN_PERL_VERSION => '5.006001' )
  )

);