use ExtUtils::MakeMaker;
WriteMakefile(
  NAME           => 'WebService::Whistle::Pet::Tracker::API',
  LICENSE        => 'mit',
  VERSION_FROM   => 'lib/WebService/Whistle/Pet/Tracker/API.pm',
  PREREQ_PM      => {
                     'JSON::XS'          => 0,
                     'HTTP::Tiny'        => 0,
                     'Tie::IxHash'       => 0,
                     'Net::MQTT::Simple' => 0,
                     'Time::HiRes'       => 0,
                    },
  ABSTRACT_FROM  => 'lib/WebService/Whistle/Pet/Tracker/API.pm',
  AUTHOR         => 'Michael R. Davis',
    EXE_FILES    => [
                    qw{
                       scripts/perl-WebService-Whistle-Pet-Tracker-API-mqtt.pl
                       scripts/perl-WebService-Whistle-Pet-Tracker-API-pets.pl
                       scripts/perl-WebService-Whistle-Pet-Tracker-API-device.pl
                      }
                    ],
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-WebService-Whistle-Pet-Tracker-API.git',
        'url' => 'git@github.com:mrdvt92/perl-WebService-Whistle-Pet-Tracker-API.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-WebService-Whistle-Pet-Tracker-API',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-WebService-Whistle-Pet-Tracker-API/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);
