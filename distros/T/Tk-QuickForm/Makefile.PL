use ExtUtils::MakeMaker;

WriteMakefile(
	NAME						=> 'Tk::QuickForm',
	VERSION_FROM			=> 'lib/Tk/QuickForm.pm',
	PREREQ_PM				=> {
		'Scalar::Util::Numeric' => 0,
		'Test::Tk'		=> '3.02',
		'Tk'			=> '804.033',
		'Tk::ColorEntry'	=> '0.08',
		'Tk::FontDialog'	=> 0,
		'Tk::ListEntry'	=> '0.01',
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
		}}) : ()
	),
);

