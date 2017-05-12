# $Id$
use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Win32::GUIRobot',
	VERSION_FROM      => 'lib/Win32/GUIRobot.pm',
	PREREQ_PM         => {
		'Prima'		 => 1,
		'Time::HiRes'    => 1,
		(( $^O =~ /win32|cygwin/i) ? ( 
		'Win32::GuiTest' => 1 
		) : ()),
	},
	ABSTRACT_FROM     => 'lib/Win32/GUIRobot.pm',
	AUTHOR            => 'Dmitry Karasik <dmitry@karasik.eu.org>',
);
