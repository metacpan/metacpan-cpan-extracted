use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'			=> 'Win32API::GUID',
    'VERSION_FROM'	=> 'lib/Win32API/GUID.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Win32API/GUID.pm',
       AUTHOR     => 'Andrew Shitov <andy@shitov.ru>') : ())
);
