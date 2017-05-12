
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
    NAME          => 'Tk::MultiMediaControls',
    DISTNAME      => 'Tk-MultiMediaControls',
    VERSION_FROM  => 'MultiMediaControls.pm',
    PREREQ_PM     => {
        'Tk'      => '8.0.4',
    },
    PM            => {
        "MultiMediaControls.pm"     => "\$(INST_LIBDIR)/MultiMediaControls.pm",
        "images/Fast-Hi-Blue.png"   => "\$(INST_LIBDIR)/MultiMediaControls/images/Fast-Hi-Blue.png",
        "images/Fast-N-R.png"       => "\$(INST_LIBDIR)/MultiMediaControls/images/Fast-N-R.png",
        "images/Fast-N.png"         => "\$(INST_LIBDIR)/MultiMediaControls/images/Fast-N.png",
        "images/Home-Hi-Blue.png"   => "\$(INST_LIBDIR)/MultiMediaControls/images/Home-Hi-Blue.png",
        "images/Home-N-R.png"       => "\$(INST_LIBDIR)/MultiMediaControls/images/Home-N-R.png",
        "images/Home-N.png"         => "\$(INST_LIBDIR)/MultiMediaControls/images/Home-N.png",
        "images/Pause-Hi-Blue.png"  => "\$(INST_LIBDIR)/MultiMediaControls/images/Pause-Hi-Blue.png",
        "images/Pause-N-R.png"      => "\$(INST_LIBDIR)/MultiMediaControls/images/Pause-N-R.png",
        "images/Pause-N.png"        => "\$(INST_LIBDIR)/MultiMediaControls/images/Pause-N.png",
        "images/Play-Hi-Blue.png"   => "\$(INST_LIBDIR)/MultiMediaControls/images/Play-Hi-Blue.png",
        "images/Play-N-R.png"       => "\$(INST_LIBDIR)/MultiMediaControls/images/Play-N-R.png",
        "images/Play-N.png"         => "\$(INST_LIBDIR)/MultiMediaControls/images/Play-N.png",
        "images/Rewind-Hi-Blue.png" => "\$(INST_LIBDIR)/MultiMediaControls/images/Rewind-Hi-Blue.png",
        "images/Rewind-N-R.png"     => "\$(INST_LIBDIR)/MultiMediaControls/images/Rewind-N-R.png",
        "images/Rewind-N.png"       => "\$(INST_LIBDIR)/MultiMediaControls/images/Rewind-N.png",
        "images/Stop-Hi-Blue.png"   => "\$(INST_LIBDIR)/MultiMediaControls/images/Stop-Hi-Blue.png",
        "images/Stop-N-R.png"       => "\$(INST_LIBDIR)/MultiMediaControls/images/Stop-N-R.png",
        "images/Stop-N.png"         => "\$(INST_LIBDIR)/MultiMediaControls/images/Stop-N.png",
    },
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ABSTRACT      => 'QuickTime-like control buttons for multi-media players',
    AUTHOR        => 'Steve Lidie (sol0@lehigh.edu)',
);
