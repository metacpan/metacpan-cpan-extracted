
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
    NAME          => "Tk::ExecuteCommand",
    DISTNAME      => "Tk-ExecuteCommand",
    VERSION_FROM  => "ExecuteCommand.pm",
    PM            => {"ExecuteCommand.pm" => "\$(INST_LIBDIR)/ExecuteCommand.pm", "Killfam.pm" => "\$(INST_LIBDIR)/../Proc/Killfam.pm"},
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ABSTRACT      => 'ExecuteCommand widget',
    AUTHOR        => 'Steve Lidie (sol0@lehigh.edu)',
);
