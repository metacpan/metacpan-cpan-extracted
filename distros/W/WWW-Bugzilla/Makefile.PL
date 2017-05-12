use 5.006001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'WWW::Bugzilla',
    'VERSION_FROM' => 'WWW/Bugzilla.pm',     # finds $VERSION
    'PREREQ_PM'    => {
        Carp               => 0,
        WWW::Mechanize     => 1.30, # this is what I'm testing with... it has been known to work with 1.22, but its what I have...
        Class::MethodMaker => 1.08,
        Params::Validate   => 0.88,
        Crypt::SSLeay      => 0.57,
    },
);
