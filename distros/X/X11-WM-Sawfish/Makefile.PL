use 5.005;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'           => 'X11::WM::Sawfish',
    'VERSION_FROM'   => 'Sawfish.pm',
    'PREREQ_PM'      => {"X11::Protocol" => 0.03},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Sawfish.pm',
       AUTHOR        => 'Craig B. Agricola <craig@theagricolas.org>') :
      ()),
);
