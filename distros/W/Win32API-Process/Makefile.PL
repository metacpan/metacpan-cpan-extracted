use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Win32API::Process',
	'VERSION_FROM'	=> 'Process.pm',	# finds $VERSION
	'PREREQ_PM'	=> {},			# e.g., Module::Name => 1.1
	($] >= 5.005 ?				# Add these new keywords supported since 5.005
		(ABSTRACT_FROM	=> 'Process.pm',	# retrieve abstract from module
		AUTHOR		=> 'Ferdinand Prantl <prantl@host.sk>') : ()
	),
	'LIBS'		=> ['Psapi.lib'],	# e.g., '-lm'
	'DEFINE'	=> '',			# e.g., '-DHAVE_SOMETHING'
	'INC'		=> ''			# e.g., '-I/usr/include/other'
);
