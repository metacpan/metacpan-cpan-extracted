use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Unicode::Transliterate',
    'VERSION_FROM'	=> 'Transliterate.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> ['-licudt20l -licudata -licuuc -licui18n -licuctestfw -licutoolutil'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
    'MYEXTLIB' 		=> 'transwrap/libtranswrap$(LIB_EXT)',
);


sub MY::postamble {
'
$(MYEXTLIB): transwrap/Makefile
	cd transwrap && $(MAKE) $(PASSTHRU)
';
} 
