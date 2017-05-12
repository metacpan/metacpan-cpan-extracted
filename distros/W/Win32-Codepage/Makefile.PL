use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              'NAME'      => 'Win32::Codepage',
              'VERSION_FROM' => 'lib/Win32/Codepage.pm',
              'PREREQ_PM' => {
                 'Test::More' => 0,
                 'Win32::Locale' => 0.04,
              },
              'PL_FILES'        => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/Win32/Codepage.pm',
                AUTHOR => 'Clotho Advanced Media Inc., <cpan@clotho.com>') : ()),
              );
