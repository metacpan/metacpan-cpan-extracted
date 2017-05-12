use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::TheMovieDB::Search',
    VERSION_FROM      => 'lib/WWW/TheMovieDB/Search.pm', # finds $VERSION
    PREREQ_PM         => {
    	'strict' => 0,
	'warnings' => 0,
	'LWP::Simple' => 0,
	'URI::Escape' => 0,
	'Switch' => 0,
	'Exporter' => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/TheMovieDB/Search.pm', # retrieve abstract from module
       AUTHOR         => 'Paul Jobson <pjobson@gmail.com>') : ()),
);
