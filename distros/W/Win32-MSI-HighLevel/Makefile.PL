use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    dist         => {TARFLAGS => '--create --verbose --mode=0700 --file '},
    NAME         => 'Win32::MSI::HighLevel',
    VERSION_FROM => 'lib/Win32/MSI/HighLevel.pm', # finds \$VERSION
    AUTHOR       => 'Peter Jaquiery (grandpa@cpan.org)',
    LICENSE      => 'perl',
    ABSTRACT     => 'Perl wrapper for Windows Installer API',
    PREREQ_PM    => {
        'Win32::API' => 0.46,
    },
);
