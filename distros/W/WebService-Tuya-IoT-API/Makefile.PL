use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'WebService::Tuya::IoT::API',
    LICENSE        => 'mit',
    VERSION_FROM   => 'lib/WebService/Tuya/IoT/API.pm',
    PREREQ_PM      => {
                        'Time::HiRes' => 0,
                        'Digest::SHA' => 0,
                        'Data::UUID'  => 0,
                        'JSON::XS'    => 0,
                        'HTTP::Tiny'  => 0,
                        'List::Util'  => 0,
                      },
    ABSTRACT_FROM  => 'lib/WebService/Tuya/IoT/API.pm',
    AUTHOR         => 'Michael R. Davis',
    META_MERGE     => {
      'resources' => {
        'repository' => {
          'web' => 'https://github.com/mrdvt92/perl-WebService-Tuya-IoT-API.git',
          'url' => 'git@github.com:mrdvt92/perl-WebService-Tuya-IoT-API.git',
          'type' => 'git'
        },
        'homepage' => 'https://github.com/mrdvt92/perl-WebService-Tuya-IoT-API',
        'bugtracker' => {
          'web' => 'https://github.com/mrdvt92/perl-WebService-Tuya-IoT-API/issues'
        },
      },
      'meta-spec' => {
        'version' => 2
      },
    },
);
