use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Ucam::Term',
    VERSION_FROM      => 'lib/Ucam/Term.pm', # finds $VERSION
    PREREQ_PM         => {
			  DateTime => 0,
                          DateTime::Span => 0,
                          DateTime::Duration => 0,
                          Carp => 0,
                          # For tests...
                          Test::More => 0,
                          Test::Exception => 0,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Ucam/Term.pm', # retrieve abstract from module
       AUTHOR         => 'Jon Warbrick <jw35@cam.ac.uk>') : ()),
);
