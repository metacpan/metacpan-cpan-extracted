
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
    NAME          => "Tk::Gauge",
    DISTNAME      => "Tk-Gauge",
    VERSION_FROM  => "Tk/Gauge.pm",
    PREREQ_PM     => {
        'Tk'                     => '8.4.27',
    },
    PM            => {
        "Tk/Gauge.pm"              => "\$(INST_LIBDIR)/Gauge.pm",
        "Tk/Labelled.pm"           => "\$(INST_LIBDIR)/Labelled.pm",
    },
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ABSTRACT      => 'Crate a variety of analog gauges.',
    AUTHOR        => 'Steve Lidie (sol0@lehigh.edu)',
);
