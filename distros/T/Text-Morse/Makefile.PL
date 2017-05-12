use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "Encode and decode Morse code",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'Text::Morse',
  VERSION  => '0.07',

  PREREQ_PM => {
          'Test::More' => 0,
          'Test::Simple' => '0'
        },

  ( $ExtUtils::MakeMaker::VERSION < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                no_index => {directory => [qw/t/]},
                provides => 

	{
          'Text::Morse' => {
                             'version' => '0.07',
                             'file' => 'lib/Text/Morse.pm'
                           }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-Text-Morse.git',
                        web  => 'http://github.com/bennie/perl-Text-Morse',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=Text-Morse',
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