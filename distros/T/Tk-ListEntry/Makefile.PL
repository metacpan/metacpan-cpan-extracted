use ExtUtils::MakeMaker;

WriteMakefile(
	NAME					=> 'Tk::ListEntry',
	VERSION_FROM		=> 'lib/Tk/ListEntry.pm',
	PREREQ_PM			=> {
		'Test::Tk'		=> '3.02',
		'Tk'				=> '804.033',
		'Tk::PopList'	=> '0.13',
	},
	ABSTRACT_FROM		=> 'lib/Tk/ListEntry.pm',
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE				=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/haje61/Tk-ListEntry.git',
				web  => 'https://github.com/haje61/Tk-ListEntry',
			},
         bugtracker => {
            web  => "https://github.com/haje61/Tk-ListEntry/issues",
         },
		}}) : ()
	),
);


