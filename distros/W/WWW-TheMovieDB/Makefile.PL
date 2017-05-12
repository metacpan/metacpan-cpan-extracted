use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::TheMovieDB',
    VERSION_FROM      => 'lib/WWW/TheMovieDB.pm', # finds $VERSION
    PREREQ_PM         => {
        'HTTP::Request'    => '5.80',
        'LWP::UserAgent'   => '5.80',
        'URI::Escape'      => '3.20',
	'JSON'             => '2.50'	
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/TheMovieDB.pm', # retrieve abstract from module
       AUTHOR         => 'Paul Jobson <pjobson@gmail.com>') : ()),
);
