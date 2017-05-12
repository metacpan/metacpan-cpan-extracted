
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
    NAME          => "Tk::ProgressBar::Mac",
    DISTNAME      => "Tk-ProgressBar-Mac",
    VERSION_FROM  => "Mac.pm",
    PM            => {"Mac.pm" => "\$(INST_LIBDIR)/Mac.pm"},
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ABSTRACT      => 'Macintosh Classic ProgressBar widget',
    AUTHOR        => 'Steve Lidie (sol0@lehigh.edu)',
);
