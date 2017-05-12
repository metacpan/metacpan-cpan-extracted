use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Solaris::Patchdiag',
    'VERSION_FROM' => 'Patchdiag.pm', # finds $VERSION
    'AUTHOR' => 'Chris Josephes <chrisj@onvoy.com>',
    'ABSTRACT' => 'Reads in a patchdiag.xref file',
);
