
use ExtUtils::MakeMaker;
use 5.007;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
    dist         => {TARFLAGS => '--create --verbose --mode=0700 --file '},
    NAME         => 'Video::Dumper::QuickTime',
    VERSION_FROM => 'lib/Video/Dumper/QuickTime.pm',         # finds \$VERSION
    AUTHOR       => 'Peter Jaquiery (grandpa@cpan.org)',
    LICENSE      => 'perl',
    ABSTRACT     => 'Dump QuickTime movie file structure',
    PREREQ_PM    => {
        'Test::More'          => 0.62,
    },
);
