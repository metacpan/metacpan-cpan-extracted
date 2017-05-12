use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Solaris::Contents',
    'VERSION_FROM' => 'Contents.pm', # finds $VERSION
    'AUTHOR' => 'Chris Josephes <chrisj@onvoy.com>',
    'ABSTRACT' => 'Reads Solaris contents file'
);
