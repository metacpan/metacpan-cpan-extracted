use ExtUtils::MakeMaker;

WriteMakefile (
	'NAME'		=> 'Tk::ApplicationNest',
	'DISTNAME'	=> 'Tk-ApplicationNest',
	'VERSION'	=> '1.1',
	'AUTHOR'	=> 'Frank Herrmann <xpix@netzwert.ag>',
	'PREREQ_PM' 	=> { 	'Tk' => 0, 
				'Tk::Getopt' => 0, 
				'Tk::Balloon' => 0, 
				'Tk::ToolBar' => 0,
				'Data::Dumper' => 0,
	},
	'dist'		=> { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz' },
);

