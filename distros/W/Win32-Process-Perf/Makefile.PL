use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Win32::Process::Perf',
    'VERSION_FROM'	=> 'lib/Win32/Process/Perf.pm', # finds $VERSION
    'PREREQ_PM'		=> { Win32::Locale => 0.03, File::Basename => 2.6 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Performance counter for processes', 
       AUTHOR     => 'Reinhard Pagitsch <rpirpag@gmx.at>') : ()),
    'LIBS'		=> ['pdh.lib', 'Advapi32.lib'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '', # e.g., '-I/usr/include/other'
    
	# Un-comment this if you add C files to link with later:
    'OBJECT'		=> '$(O_FILES)', # link all the C files too
    'DISTNAME' => 'Win32-Process-Perf',
    'dist'      => { COMPRESS=>"gzip", SUFFIX=>"gz" }
);
