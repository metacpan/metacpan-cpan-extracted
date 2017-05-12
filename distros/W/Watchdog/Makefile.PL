use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	     => 'Watchdog::Service',
	      'DISTNAME'     => 'Watchdog',
	      'VERSION_FROM' => 'Base.pm',
	      'PREREQ_PM'    => { 'Alias' => 0, 'Proc::ProcessTable' => 0, },
	      #'EXE_FILES'    => [ 'bin/dogd', 'bin/httpdog' ],
);
