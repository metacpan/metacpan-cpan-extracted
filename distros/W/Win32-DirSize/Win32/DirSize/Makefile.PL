use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'				=> 'Win32::DirSize',
    'VERSION_FROM'		=> 'DirSize.pm',
    'PREREQ_PM'			=> {},
    ($] >= 5.005 ? (
	ABSTRACT_FROM		=> 'DirSize.pm',
	AUTHOR				=> 'Adam Rich <arich@cpan.org>',
	) : ()),
    'LIBS'				=> ['Kernel32.lib'],
    'DEFINE'			=> '/TP /W3',
    'INC'				=> '',
    'OBJECT'			=> '$(O_FILES)',
);
