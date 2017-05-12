use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "Parsing tab delimited files",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'Text::TabFile',
  VERSION  => '1.14',

  PREREQ_PM => {
          'Test' => '0',
          'Text::Delimited' => '2.00'
        },

  ( $ExtUtils::MakeMaker::VERSION < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                no_index => {directory => [qw/t/]},
                provides => 

	{
          'Text::TabFile' => {
                               'version' => '1.14',
                               'file' => 'lib/Text/TabFile.pm'
                             }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-Text-TabFile.git',
                        web  => 'http://github.com/bennie/perl-Text-TabFile',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=Text-TabFile',
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