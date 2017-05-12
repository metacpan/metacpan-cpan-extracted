use ExtUtils::MakeMaker;

# Check for my patched version of HList.
use Tk::HList;

unlink "Tk/HList.pm";
my $need;
if( $Tk::HList::VERSION =~ /ctd/ ) {
    $need = "Installed HList.pm is based on the patched version from Tk-Tree.";
} elsif( $Tk::HList::VERSION <= 2.013 ) {
    $need = "Installed HList.pm is an older unpatched version.";
} else {
    warn "Installed HList.pm is newer than patched version from Tk-Tree.\n";
    warn "Using the current installed version.\n";
}

if( $need ) {
    warn "$need\n";
    warn "Using local copy of HList.pm (will supersede installed HList.pm).\n";
    use File::Copy;
    print "HList.pm.patched -> Tk/HList.pm\n";
    copy( "HList.pm.patched", "Tk/HList.pm" );
}


# Write the Makefile
WriteMakefile(
    'NAME'          => 'Tk-Tree',
    'VERSION_FROM'  => 'Tk/Tree.pm', # finds $VERSION
    'dist'          => {
        COMPRESS        => 'gzip -9f',
        SUFFIX          => '.gz', 
        DIST_DEFAULT    => 'all tardist',
    },
    clean           => { FILES => "Tk/HList.pm" },
    PMLIBDIRS       => ['Tk'],
    PREREQ_PM       => { Tk => 402.002 },
);
