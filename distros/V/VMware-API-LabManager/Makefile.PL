use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "VMware's Lab Manager public and private API",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'VMware::API::LabManager',
  VERSION  => '2.11',

  PREREQ_PM => {
          'SOAP::Lite' => '0.71',
          'Net::SSL' => 0,
          'Data::Dumper' => 0
        },

  ( $ExtUtils::MakeMaker::VERSION < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                no_index => {directory => [qw/t/]},
                provides => 

	{
          'VMware::API::LabManager' => {
                                         'version' => '2.11',
                                         'file' => 'lib/VMware/API/LabManager.pm'
                                       }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-VMware-API-LabManager.git',
                        web  => 'http://github.com/bennie/perl-VMware-API-LabManager',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=VMware-API-LabManager',
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