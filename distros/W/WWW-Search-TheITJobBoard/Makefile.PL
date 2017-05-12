use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Search::TheITJobBoard',
    VERSION_FROM      => 'lib/WWW/Search/TheITJobBoard.pm', # finds $VERSION
    PREREQ_PM         => {
		'WWW::Search'	=> 0.1,
		'WWW::SearchResult' => 0.1,
		'HTML::TokeParser'  => 0.1,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Search/TheITJobBoard.pm', # retrieve abstract from module
       AUTHOR         => 'lee goddard <lgoddard -at- cpan -dot- org>') : ()),
);
