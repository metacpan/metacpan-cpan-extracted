use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	'NAME'         => 'Win32::GUI::XMLBuilder',
	'VERSION_FROM' => 'lib/Win32/GUI/XMLBuilder.pm',
	'PM' => {
		'lib/Win32/GUI/XMLBuilder.pm' => '$(INST_LIBDIR)/XMLBuilder.pm',
	},
	PREREQ_PM   => {
		'Win32::GUI'	=> '1.05',
		'XML::Twig'		=> '3.14',
	},
	($] ge '5.005') ?
	(
		'AUTHOR'   => 'Blair Sutton (bsdz@cpan.org)',
		'ABSTRACT' => 'Build Win32::GUIs using XML',
	)
	: (),
);


