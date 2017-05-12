use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Time::Vector',
	VERSION_FROM	=> 'lib/Time/Vector.pm',
	ABSTRACT	=> 'A bit for every minute',
#	ABSTRACT_FROM	=> 'lib/Time/Vector.pm',
	AUTHOR		=> 'Alessandro Zummo <a.zummo@towertech.it>',
	LICENSE		=> 'GPLv2',
	PREREQ_PM	=> {
				'Bit::Vector'		=> 0,
				'Time::Simple::Range'	=> 0,
				'Class::Accessor::Fast'	=> 0,
				'Time::Seconds'		=> 0,
			},			
);
