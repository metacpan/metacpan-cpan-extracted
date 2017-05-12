use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WebService::Riya',
    VERSION_FROM      => 'lib/WebService/Riya.pm', # finds $VERSION
    PREREQ_PM         => {
        Class::Accessor::Fast => 0.25,
        HTTP::Request::Common => 1.26,
        LWP => 0,
        Test::More => 0.32,
        URI => 1.35,
        XML::LibXML => 1.60,
    },
);
