use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'WWW::FoneFinder',
    VERSION_FROM   => 'lib/WWW/FoneFinder.pm',
    PREREQ_PM      => {
                        LWP::UserAgent => 5,
                      },
    ABSTRACT_FROM  => 'lib/WWW/FoneFinder.pm',
    AUTHOR         => 'Dusty Wilson <dusty@megagram.com>',
);
