use ExtUtils::MakeMaker;

WriteMakefile (
	NAME		=> 'Tk::Graph',
	DISTNAME	=> 'Tk-Graph',
	VERSION		=> '0.06',
	AUTHOR		=> 'Frank Herrmann <xpix@netzwert.ag>',
	ABSTRACT	=> 'Tk::Graph - Realtime Chartmaker Widget',
	PREREQ_PM   	=> {
		'Tk'		=> '0',
        	'Tie::Watch'    => '0', 
		'Math::Trig'	=> '0',
	},
);

