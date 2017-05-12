
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
    NAME          => "Tk::SlideSwitch",
    DISTNAME      => "Tk-SlideSwitch",
    VERSION_FROM  => "SlideSwitch.pm",
    PM            => {"SlideSwitch.pm" => "\$(INST_LIBDIR)/SlideSwitch.pm"},
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ABSTRACT      => 'Binary sliding switch widget',
    AUTHOR        => 'Steve Lidie (sol0@lehigh.edu)',
);
