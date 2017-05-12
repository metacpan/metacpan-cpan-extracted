use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Win32::AbsPath',
    'VERSION_FROM' => 'AbsPath.pm', # finds $VERSION
    'AUTHOR' => 'Jan Krynicky (Jenda@Krynicky.cz),Mike (blazer@mail.nevalink.ru)',
    'ABSTRACT' => 'convert relative to absolute paths',
);
