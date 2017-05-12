use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "Delimited Text Processing",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'Text::Delimited',
  VERSION  => '2.11',

  PREREQ_PM => {
          'Test::More' => 0,
          'Test::Simple' => '0',
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
                                 'version' => '2.11',
                                 'file' => 'lib/Text/Delimited.pm'
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