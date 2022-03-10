
use ExtUtils::MakeMaker;

rename('README.md','README') if -f 'README.md';

WriteMakefile(
	NAME		=> 'Text::NSR',
	AUTHOR		=> 'Clipland (clipland@cpan.org)',
	ABSTRACT_FROM	=> 'lib/Text/NSR.pm',
	VERSION_FROM	=> 'lib/Text/NSR.pm',
	LICENSE	=> 'artistic_2',
	PREREQ_PM	=> {
		"Path::Tiny"		=> 0,
	},
	META_MERGE	=> {
		'meta-spec'	=> { version => 2 },
		resources	=> {
			repository => 'https://github.com/clipland/text-nsr',
			bugtracker => 'https://github.com/clipland/text-nsr/issues'
		},
	},
	dist => {
		POSTOP => 'perl -e "rename(\'README\',\'README.md\') if -f \'README\'"',
	},
	realclean => {
		POSTOP => 'perl -e "rename(\'README\',\'README.md\') if -f \'README\'"',
	},
	MIN_PERL_VERSION	=> 5.004, # nothing special in this dist, let's just make CPANTS happier
);
