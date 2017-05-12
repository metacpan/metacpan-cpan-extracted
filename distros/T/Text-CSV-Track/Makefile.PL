use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Text::CSV::Track',
	VERSION_FROM      => 'lib/Text/CSV/Track.pm', # finds $VERSION
	PREREQ_PM         => {
    	Class::Accessor::Fast => 0,
		Text::CSV_XS          => 0,
		Carp::Clan            => 0,
		List::MoreUtils       => 0,
		IO::Handle            => 0,
		File::Slurp           => 0,
	}, # e.g., Module::Name => 1.1
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM  => 'lib/Text/CSV/Track.pm', # retrieve abstract from module
       AUTHOR         => 'Jozef Kutej <jozef.kutej@hp.com>') : ()
	),
	(MM->can('signature_target') ? (SIGN => 1) : ()),
	NO_META => 1,
);
