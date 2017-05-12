use ExtUtils::MakeMaker;

WriteMakefile (
	'NAME'		=> 'Tk::XDialogBox',
	'DISTNAME'	=> 'Tk-XDialogBox',
	'VERSION'	=> '0.01',
	'AUTHOR'	=> 'Frank Herrmann <xpix@netzwert.ag>',
	'PREREQ_PM' 	=> { 'Tk' => 0 },

	'dist'		=> { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz' },
);

