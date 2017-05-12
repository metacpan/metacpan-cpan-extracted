#   $Id: Makefile.PL 93 2012-06-18 10:18:15Z adam $

use 5.008000; use 5.8.0;
use strict;
use ExtUtils::MakeMaker;

if ($] < 5.0010) {
    print {*STDERR} "\n##########################################",
                    "\n# This module is not supported on Perls  #",
                    "\n# older than 5.8.x. Patches are welcome. #",
                    "\n##########################################\n\n";
}

eval { require Module::Build };
if (! $@) {
    print {*STDERR} "\n############################################",
                     "\n# This Makefile.PL is deprecated and not  #",
                     "\n# supported any more. Please use Build.PL #",
                     "\n# file instead.                           #",
                     "\n###########################################\n\n";
}

WriteMakefile(
    'NAME'      => 'XML::RSS::Tools',
    'VERSION_FROM'     => 'lib/XML/RSS/Tools.pm',
    'PREREQ_PM'        => {
        'URI'          => 1.35,
        'XML::LibXSLT' => 1.59,
        'XML::LibXML'  => 1.59,
        'XML::RSS'     => 1.22,
        'LWP'          => 5.8,
        },
    'PL_FILES'      => {},
    dist             => {
       COMPRESS      => 'gzip -9f',
       SUFFIX        => 'gz'
       },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/XML/RSS/Tools.pm',
       AUTHOR        => 'Dr A. J. Trickett <atrickett@cpan.org>') : ()),
);
