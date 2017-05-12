use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'			=> 'Win32::ToolHelp',
	'VERSION_FROM'	=> 'ToolHelp.pm',	# finds $VERSION
	'PREREQ_PM'		=> {},				# e.g., Module::Name => 1.1
	($] >= 5.005 ? (
	  ABSTRACT_FROM	=> 'ToolHelp.pm',	# retrieves abstract from module
	  AUTHOR		=> 'Ferdinand Prantl <prantl@host.sk>') : ()),
	'LIBS'			=> [''],			# e.g., '-lm'
	'DEFINE'		=> '',				# e.g., '-DHAVE_SOMETHING'
	'INC'			=> '',		# e.g., '-I/usr/include/other'
	#'OBJECT'		=> '$(O_FILES)',		# link all the C files too
	'MYEXTLIB'		=> 'Impl/Impl$(LIB_EXT)',
	dist			=> {TARFLAGS => '--mode=755 -c -v -f'},
);

sub MY::postamble {
'
$(MYEXTLIB): Impl/Makefile
	cd Impl && $(MAKE) $(PASSTHRU)
';
}
