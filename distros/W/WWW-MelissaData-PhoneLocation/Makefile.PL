use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'WWW::MelissaData::PhoneLocation',
    VERSION_FROM   => 'lib/WWW/MelissaData/PhoneLocation.pm',
    PREREQ_PM      => {
                        LWP::UserAgent => 5,
                      },
    ABSTRACT_FROM  => 'lib/WWW/MelissaData/PhoneLocation.pm',
    AUTHOR         => 'Dusty Wilson <dusty@megagram.com>',
);
