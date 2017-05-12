use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Win32::MprApi',
    'VERSION_FROM'	=> 'MprApi.pm', # finds $VERSION
    'BINARY_LOCATION' => 'Win32-MprApi-0.02.tar.gz',
    'PREREQ_PM'		=> { 'Win32::API' => 0.20 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MprApi.pm', # retrieve abstract from module
       AUTHOR     => 'Luigino Masarati <lmasarati@hotmail.com>') : ()),
);
