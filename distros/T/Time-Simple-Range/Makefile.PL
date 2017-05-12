use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Time::Simple::Range',
	'VERSION_FROM'	=> 'lib/Time/Simple/Range.pm',
	'ABSTRACT_FROM'	=> 'lib/Time/Simple/Range.pm',
	'AUTHOR'	=> 'Alessandro Zummo <a.zummo@towertech.it>',
	'LICENSE'	=> 'GPLv2',
	'PREREQ_PM'	=> {
				'Time::Simple'		=> 0,
				'Class::Accessor'	=> 0,
				'Time::Seconds'		=> 0,
			},			
);
