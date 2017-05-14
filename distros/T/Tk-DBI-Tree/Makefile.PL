use ExtUtils::MakeMaker;

WriteMakefile (
	'NAME'		=> 'Tk::DBI::Tree',
	'DISTNAME'	=> 'Tk-DBI-Tree',
	'VERSION'	=> '0.04',
	'AUTHOR'	=> 'Frank Herrmann <xpix@netzwert.ag>',
	'PREREQ_PM' 	=> { 	'Tk' => 0, 
				'Tk::ResizeButton' => 0, 
				'DBIx::Tree' => 0, 
				'Term::ANSIColor' => 0,
	},
	'dist'		=> { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz' },
);

