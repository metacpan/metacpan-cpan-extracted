use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Win32::Fonts::Info',
    'VERSION_FROM'	=> 'Info.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Info.pm', # retrieve abstract from module
       AUTHOR     => 'Reinhard Pagitsch <rpirpag@gmx.at>') : ()),
    'LIBS'		=> ($^O =~ /cygwin/i ?
			    ['-L/usr/lib/w32api -lGdi32'] : ['Gdi32.lib']),
    'DEFINE'		=> '-Zi', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
