
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
    NAME          => "Tk::Thumbnail",
    DISTNAME      => "Tk-Thumbnail",
    VERSION_FROM  => "Thumbnail.pm",
    PREREQ_PM     => {
        'Tk'                     => '8.0.4',
        'Tk::MultiMediaControls' => '1.0',
    },
    PM            => {
        "Thumbnail.pm"              => "\$(INST_LIBDIR)/Thumbnail.pm",
        "images/info3.png"          => "\$(INST_LIBDIR)/Thumbnail/images/info3.png",
    },
    EXE_FILES     => ['tkthumb'],
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ABSTRACT      => 'Display thumbnail images of Photos',
    AUTHOR        => 'Steve Lidie (sol0@lehigh.edu)',
);
