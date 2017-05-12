use ExtUtils::MakeMaker;

WriteMakefile (
	'NAME'		=> 'Tk::HexEntry',
	'DISTNAME'	=> 'Tk-HexEntry',
	'VERSION'	=> '0.01',
	'AUTHOR'	=> 'Frank Herrmann <xpix@netzwert.ag>',
	'PREREQ_PM' 	=> { 'Tk' => 0, 'Tk::FireButtonWidget' => 0 },

	'dist'		=> { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz' },
);

