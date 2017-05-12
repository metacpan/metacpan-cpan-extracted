
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
    NAME          => "Tk::Copy::Mac",
    DISTNAME      => "Tk-Copy-Mac",
    VERSION_FROM  => "Mac.pm",
    PM            => {"Mac.pm" => "\$(INST_LIBDIR)/Mac.pm", "NCopy.pm" => "\$(INST_LIBDIR)/../../File/NCopy.pm"},
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ABSTRACT      => 'Macintosh Classic Copy widget',
    AUTHOR        => 'Steve Lidie (sol0@lehigh.edu)',
);
