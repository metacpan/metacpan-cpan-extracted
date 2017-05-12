use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Time::Consts',
    VERSION_FROM => 'lib/Time/Consts.pm', # finds $VERSION
    AUTHOR       => 'Johan Lodin <lodin@cpan.org>',
    ABSTRACT     => 'Time::Consts',
    PREREQ_PM    => {
        Test::More => 0.45,
    },
);
