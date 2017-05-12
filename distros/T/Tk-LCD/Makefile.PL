
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
    NAME          => "Tk::LCD",
    DISTNAME      => "Tk-LCD",
    VERSION_FROM  => "LCD.pm",
    PM            => {"LCD.pm" => "\$(INST_LIBDIR)/LCD.pm"},
    dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    ABSTRACT      => 'Liquid Crystal Display widget',
    AUTHOR        => 'Steve Lidie (sol0@lehigh.edu)',
);
