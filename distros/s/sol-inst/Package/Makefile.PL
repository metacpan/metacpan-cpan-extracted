use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Solaris::Package',
    'VERSION_FROM' => 'Package.pm', # finds $VERSION
    'AUTHOR' => 'Chris Josephes <chrisj@onvoy.com>',
    'ABSTRACT' => 'Reads the pkginfo file of a Solaris package',
);
