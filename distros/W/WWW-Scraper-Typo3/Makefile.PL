use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage <ron@savage.net.au>',
		ABSTRACT => 'Clean up Typo3-based web site files',
    ) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST WWW-Scraper-Typo3-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'WWW-Scraper-Typo3',
	NAME      => 'WWW::Scraper::Typo3',
	PL_FILES  => {},
	PREREQ_PM =>
	{
		common::sense     => 3.0,
		File::chdir       => 0.1003,
		File::Copy        => 2.11,
		File::Slurp       => 9999.13,
		File::Temp        => 0,
		HTML::TreeBuilder => 3.23,
		LWP::Simple       => 5.827,
		Moose             => 1.09,
	},
	VERSION_FROM => 'lib/WWW/Scraper/Typo3.pm',
);
