use ExtUtils::MakeMaker;

WriteMakefile(
	NAME					=> 'Tk::ITree',
	VERSION_FROM		=> 'lib/Tk/ITree.pm',
	PREREQ_PM			=> {
		'Test::Tk'		=> '0.03',
		'Tk'				=> '804.033',
	},
	ABSTRACT_FROM		=> 'lib/Tk/ITree.pm',
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE				=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/haje61/Tk-ITree.git',
				web  => 'https://github.com/haje61/Tk-ITree',
			},
		}}) : ()
	),
);

