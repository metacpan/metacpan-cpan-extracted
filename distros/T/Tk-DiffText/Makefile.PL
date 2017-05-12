use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Tk::DiffText',
	VERSION_FROM      => 'lib/Tk/DiffText.pm',
	PREREQ_PM         => {
		'Tk'              => 0,
		'Algorithm::Diff' => 1.13,
		'Tie::Tk::Text'   => 0.01,
		'IO::File'        => 0,
	},
	($] >= 5.005 ?
	  (ABSTRACT_FROM  => 'lib/Tk/DiffText.pm',
	   AUTHOR         => 'Michael J. Carman <mjcarman@mchsi.com>') : ()),
);

# build requires Test::More v0.42
