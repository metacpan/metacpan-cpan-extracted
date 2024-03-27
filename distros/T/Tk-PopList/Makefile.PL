use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Tk::PopList',
	VERSION_FROM => 'lib/Tk/PopList.pm',
	PREREQ_PM => {
		'Tk' => 0,
		'Test::Tk' => '3.02',
	},
	ABSTRACT_FROM => 'lib/Tk/PopList.pm',
	AUTHOR => 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE => 'perl',

	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/haje61/Tk-PopList.git',
				web  => 'https://github.com/haje61/Tk-PopList',
			},
		}}) : ()
	),
);


