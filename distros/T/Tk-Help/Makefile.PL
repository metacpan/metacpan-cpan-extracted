use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		 => 'Tk::Help',
	VERSION_FROM => 'lib/Tk/Help.pm',
	PREREQ_PM	 => {'Tk' => 0},
	($] >= 5.005 ? (ABSTRACT_FROM => 'lib/Tk/Help.pm',
					AUTHOR		  => 'Doug Gruber <dougthug@cpan.org>') : ()));