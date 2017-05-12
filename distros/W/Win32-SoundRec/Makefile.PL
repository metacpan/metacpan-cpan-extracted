use ExtUtils::MakeMaker;

die "Win32::SoundRec can only be installed on Microsoft Windows Platforms\n Makefile not written\n\n" unless $^O eq 'MSWin32';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Win32::SoundRec',
    VERSION_FROM => 'lib/Win32/SoundRec.pm', # finds $VERSION
    AUTHOR       => 'Jouke Visser <jouke@cpan.org>',
    ABSTRACT_FROM=> 'lib/Win32/SoundRec.pm',
    PREREQ_PM    => {   'Win32::API::Prototype'            => 0}
);
