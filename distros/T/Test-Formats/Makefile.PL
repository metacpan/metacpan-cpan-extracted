###############################################################################
#
#   $Id: Makefile.PL 10 2008-10-22 09:57:04Z rjray $
#
#   ExtUtils::MakeMaker file for Test::Formats
#
###############################################################################

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::Spec;

WriteMakefile(
    NAME                => 'Test::Formats',
    AUTHOR              => 'Randy J. Ray <rjray@blackperl.com>',
    VERSION             => '0.12',
    LICENSE             => 'perl',
    ABSTRACT            => 'Test::Builder-based testing of XML, etc. content',
    PREREQ_PM => {
        'File::Spec'    => '0.8',
        'XML::LibXML'   => '1.60',
        'Exporter'      => '5.57',
        'Test::Simple'  => '0.80',
    },
    SIGN                => 'here, please',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Formats-*' },
    test                => {
        TESTS => 't/*.t t/10_xml/*.t t/90_integration/*.t'
    },
);

exit 0;
