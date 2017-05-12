use strict;
use 5.008;

use ExtUtils::MakeMaker;

main: {
    my $package;
    eval {
        require ExtUtils::Depends;
        require ExtUtils::PkgConfig;

        my %libaosd = ExtUtils::PkgConfig->find("libaosd");
        $package = ExtUtils::Depends->new('X11::Aosd', 'Cairo', 'Gtk2');

        $package->set_inc($libaosd{cflags});
        $package->set_libs($libaosd{libs});
    };
    
    WriteMakefile(
        NAME            => 'X11::Aosd',
        VERSION_FROM    => 'lib/X11/Aosd.pm',
        ABSTRACT_FROM   => 'lib/X11/Aosd.pm',
        AUTHOR          => 'Joern Reder <joern AT zyn DOT de>',
        PREREQ_PM       => {
            'Cairo'                 => 0,
            'Gtk2'                  => 0,
            'ExtUtils::Depends'     => 0,
            'ExtUtils::PkgConfig'   => 0,
            'Test::More'            => 0,
        },
        'dist' => {
            COMPRESS => "gzip",
            SUFFIX   => "gz",
            POSTOP   => q[mkdir -p dist && mv X11-Aosd*tar.gz dist/],
        },
        ($package ? $package->get_makefile_vars() : ())
    );

    if  ( eval {require ExtUtils::Constant; 1} ) {
        my @names = (
            { name => "COORDINATE_CENTER",      macro => 1 },
            { name => "COORDINATE_MAXIMUM",     macro => 1 },
            { name => "COORDINATE_MINIMUM",     macro => 1 },
            { name => "TRANSPARENCY_COMPOSITE", macro => 1 },
            { name => "TRANSPARENCY_FAKE",      macro => 1 },
            { name => "TRANSPARENCY_NONE",      macro => 1 },
        );

        ExtUtils::Constant::WriteConstants(
            NAME         => 'X11::Aosd',
            NAMES        => \@names,
            DEFAULT_TYPE => 'IV',
            C_FILE       => 'const-c.inc',
            XS_FILE      => 'const-xs.inc',
        );
    }
    else {
        use File::Copy;
        use File::Spec;

        foreach my $file ('const-c.inc', 'const-xs.inc') {
            my $fallback = File::Spec->catfile('fallback', $file);
            copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
        }
    }
}
