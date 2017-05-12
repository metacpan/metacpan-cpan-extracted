use ExtUtils::MakeMaker;

WriteMakefile (
	'NAME'		=> 'Tk::Program',
	'DISTNAME'	=> 'Tk-Program',
	'VERSION'	=> '0.03',
	'AUTHOR'	=> 'Frank Herrmann <xpix@netzwert.ag>',
	'PREREQ_PM' 	=> { 	'Tk' => 0, 
				'Tk::Getopt' => 0, 
				'Tk::Balloon' => 0, 
				'Tk::Splashscreen' => 0,
				'Tk::ToolBar' => 0,
	},
	'dist'		=> { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz' },
);

