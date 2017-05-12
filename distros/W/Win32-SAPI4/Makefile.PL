use ExtUtils::MakeMaker;

die "Win32::SAPI4 can only be installed on Microsoft Windows Platforms\n Makefile not written\n\n" unless $^O eq 'MSWin32';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Win32::SAPI4',
    VERSION_FROM => 'lib/Win32/SAPI4.pm', # finds $VERSION
    AUTHOR       => 'Jouke Visser <jouke@cpan.org>',
    ABSTRACT_FROM=> 'lib/Win32/SAPI4.pm',
    PREREQ_PM    => {   'Win32::OLE'            => 0,
                        'Win32::OLE::Variant'   => 0,
                        'Win32::OLE::Enum'      => 0,
                        'Win32::Locale'         => 0,
                        'Locale::Codes'         => 0}
);
