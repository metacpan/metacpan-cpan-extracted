use ExtUtils::MakeMaker;

WriteMakefile (
	'NAME'		=> 'Tk::IPEntry',
	'DISTNAME'	=> 'Tk-IPEntry',
	'VERSION'	=> '0.03',
	'AUTHOR'	=> 'Frank Herrmann <xpix@netzwert.ag>',
	'PREREQ_PM' 	=> { 
		'Tk' => 0, 
		'Tie::Watch' => 0, 
		'Tk::NumEntry' => 0, 
		'Tk::HexEntry' => 0,
		'Net::IP' => 0,
	},

	'dist'		=> { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz' },
);

