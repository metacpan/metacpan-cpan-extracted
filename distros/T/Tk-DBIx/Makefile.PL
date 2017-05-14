use ExtUtils::MakeMaker;

WriteMakefile (
	'NAME'		=> 'Tk::DBIx',
	'DISTNAME'	=> 'Tk-DBIx',
	'VERSION'	=> '0.01',
	'AUTHOR'	=> 'Frank Herrmann <xpix@netzwert.ag>',
	'PREREQ_PM' 	=> { 	'Tk' => 0, 
				'Tk::ResizeButton' => 0, 
				'DBIx::Tree' => 0, 
				'DBI => 0'
	},
	'dist'		=> { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz' },
);

