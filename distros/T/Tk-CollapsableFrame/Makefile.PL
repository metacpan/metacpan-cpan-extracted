
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
    NAME          => "Tk::CollapsableFrame",
    DISTNAME      => "Tk-CollapsableFrame",
    VERSION_FROM  => "CollapsableFrame.pm",
    PM            => {"CollapsableFrame.pm" => "\$(INST_LIBDIR)/CollapsableFrame.pm"},
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ABSTRACT      => 'CollapsableFrame widget',
    AUTHOR        => 'Steve Lidie (sol0@lehigh.edu)',
);
