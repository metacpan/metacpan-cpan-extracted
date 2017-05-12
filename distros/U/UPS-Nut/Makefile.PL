use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'UPS::Nut',
    VERSION_FROM => 'lib/UPS/Nut.pm', # finds $VERSION
    AUTHOR       => 'Kit Peters (kpeters@iname.com)',
    ABSTRACT     => 'A module for communicating with a UPS via the NUT upsd'
);
