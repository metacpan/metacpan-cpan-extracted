use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Testafy',
    VERSION_FROM      => 'lib/WWW/Testafy.pm', # finds $VERSION
    PREREQ_PM         => {
        Moose            => 0,
        'LWP::UserAgent' => 0,
        JSON             => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Testafy.pm', # retrieve abstract from module
       AUTHOR         => 'Grant Street Group <developers@grantstreet.com>') : ()),
);
