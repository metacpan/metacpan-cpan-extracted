use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'				=> 'Win32::RemoteTOD',
    'VERSION_FROM'		=> 'RemoteTOD.pm',
    'PREREQ_PM'			=> {},
    ($] >= 5.005 ? (
	ABSTRACT_FROM		=> 'RemoteTOD.pm',
	AUTHOR				=> 'Adam Rich <arich@cpan.org>',
	) : ()),
    'LIBS'				=> ['netapi32.lib'],
    'DEFINE'			=> '',
    'INC'				=> '',
);
