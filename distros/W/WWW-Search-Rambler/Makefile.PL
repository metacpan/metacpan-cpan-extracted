use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile (
	NAME         => 'WWW::Search::Rambler',
	VERSION      => '0.08',
	PREREQ_PM    => { 'WWW::Search' => 2.528,
			  'WWW::SearchResult' => 2.061,
			  'URI' => 1.31,
			  'Encode' => 0,
			  'URI::Escape' => 3.26,
			  'HTML::TreeBuilder' => 3.13,
			  'HTTP::Cookies' => 1.38 },
	ABSTRACT_FROM  => 'lib/WWW/Search/Rambler.pm',
	AUTHOR         => 'Artur Penttinen <ARTO@cpan.org>'
);

exit;
