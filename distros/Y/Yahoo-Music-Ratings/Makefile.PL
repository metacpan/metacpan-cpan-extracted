use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Yahoo::Music::Ratings',
    VERSION_FROM      => 'lib/Yahoo/Music/Ratings.pm', # finds $VERSION
    PREREQ_PM         => {
                          'LWP::UserAgent' => 0,
                          'XML::Simple' => 2.14,
                          }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Yahoo/Music/Ratings.pm', # retrieve abstract from module
       AUTHOR         => 'Pierre Smolarek') : ()),
);
