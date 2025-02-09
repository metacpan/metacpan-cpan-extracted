use ExtUtils::MakeMaker;

WriteMakefile(
	NAME						=> 'Tk::QuickForm',
	VERSION_FROM			=> 'lib/Tk/QuickForm.pm',
	PREREQ_PM				=> {
		'Scalar::Util::Numeric' => 0,
		'Test::Tk'		=> '3.02',
		'Tk'			=> '804.033',
		'Tk::ColorEntry'	=> '0.10',
		'Tk::FileBrowser'	=> '0.09',
		'Tk::FontDialog'	=> '0.15',
		'Tk::ListEntry'	=> '0.03',
	},
	ABSTRACT_FROM		=> 'lib/Tk/QuickForm.pm',
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE				=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/haje61/Tk-QuickForm.git',
				web  => 'https://github.com/haje61/Tk-QuickForm',
			},
			bugtracker => {
				web  => "https://github.com/haje61/Tk-QuickForm/issues",
			},
		}}) : ()
	),
);

