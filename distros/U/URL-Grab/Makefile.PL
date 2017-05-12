use 5.008007;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME				=> 'URL::Grab',
	VERSION_FROM		=> 'lib/URL/Grab.pm',
	PREREQ_PM			=> {
							LWP::UserAgent	=> 0,
							Carp			=> 0
						},
	($] >= 5.005 ?
		(ABSTRACT_FROM	=> 'lib/URL/Grab.pm', # retrieve abstract from module
		AUTHOR			=> 'Oliver Falk <oliver@linux-kernel.at>') : ()),
	dist				=> {
		COMPRESS		=> 'gzip --force --best'
	},
);
