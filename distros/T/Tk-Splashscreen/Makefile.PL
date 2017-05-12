
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
    NAME          => "Tk::Splashscreen",
    DISTNAME      => "Tk-Splashscreen",
    VERSION_FROM  => "Splashscreen.pm",
    PM            => {"Splashscreen.pm" => "\$(INST_LIBDIR)/Splashscreen.pm", "waitVariableX.pm" => "\$(INST_LIBDIR)/waitVariableX.pm"},
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ABSTRACT      => 'Splashscreen widget',
    AUTHOR        => 'Steve Lidie (sol0@lehigh.edu)',
);
