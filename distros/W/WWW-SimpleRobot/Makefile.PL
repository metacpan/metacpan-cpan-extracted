use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::SimpleRobot',
    'EXE_FILES'         => [ 'eg/stresstest.pl', 'eg/blinks.pl' ],
    'VERSION_FROM'	=> 'SimpleRobot.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        URI             => undef,
        LWP::Simple     => undef,
        HTML::LinkExtor => undef,
    }, # e.g., Module::Name => 1.1
);
