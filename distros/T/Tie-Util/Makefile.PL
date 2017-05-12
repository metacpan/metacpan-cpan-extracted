BEGIN { require 5.008 } # \[$@%*]

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tie::Util',
    AUTHOR              => 'Father Chrysostomos <sprout & cpan . org>',
    VERSION_FROM        => 'lib/Tie/Util.pm',
    ABSTRACT_FROM       => 'lib/Tie/Util.pm',
    PREREQ_PM => {
         B             => 0,
         constant      => 0,
         Exporter      => 5.57,
        'Scalar::Util' => 1.09, # reftype
# for testing only:
         overload      => 0,
         Symbol        => 0,
#        'Test::More'   => 0,
         warnings      => 0,
    },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'Tie-Util-*' },
);
