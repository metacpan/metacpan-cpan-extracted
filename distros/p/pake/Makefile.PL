use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'pake',
    'DISTNAME' => 'pake',
    'EXE_FILES' => ['pake'],
    'VERSION_FROM' => 'pake',
    'PREREQ_PM' => {
	'Getopt::Std' => '1.05'
    },
    'PRINT_PREREQ' => 1
    );
