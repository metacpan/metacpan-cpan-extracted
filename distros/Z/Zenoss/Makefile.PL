use 5.008003;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Zenoss',
    VERSION_FROM      => 'lib/Zenoss.pm',
    PREREQ_PM         => {
        Carp                    => 0,
        JSON                    => 2.0,
        Moose                   => 1.0,
        'File::Find'            => 0,
        'File::Basename'        => 0,
        'LWP::UserAgent'        => 0,
        'HTTP::Request::Common' => 0,
        'IO::Socket::INET'      => 0,
        'Test::More'            => 0,
    },
    ($] >= 5.005 ? (
          ABSTRACT_FROM    => 'lib/Zenoss.pm',
          AUTHOR           => 'Patrick Baker <patricksbaker@gmail.com>',
          LICENSE          => 'artistic_2',
     ) : ()),
);