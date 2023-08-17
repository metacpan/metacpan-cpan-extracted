use ExtUtils::MakeMaker;

WriteMakefile(
	NAME					=> 'Tk::YADialog',
	VERSION_FROM		=> 'lib/Tk/YADialog.pm',
	PREREQ_PM			=> {
		'Test::Tk'		=> '0.03',
		'Tk'				=> '804.033',
	},
	ABSTRACT_FROM		=> 'lib/Tk/YADialog.pm',
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE				=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/haje61/Tk-YADialog.git',
				web  => 'https://github.com/haje61/Tk-YADialog',
			},
		}}) : ()
	),
);

