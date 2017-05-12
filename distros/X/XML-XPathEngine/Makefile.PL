use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::XPathEngine',
    AUTHOR              => 'Michel Rodriguez <mirod@cpan.org>',
    VERSION_FROM        => 'lib/XML/XPathEngine.pm',
    ABSTRACT_FROM       => 'lib/XML/XPathEngine.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-XPathEngine-*' },
);
# add the license bit in META.yaml
unless( `$^X -n -e'print if( m{license\\s*:\\s*perl})' Makefile`)
  { system $^X . q{ -p -i -e's{^((.*)distribution_type: module(.*))}{$1\n$2license: perl$3}m' Makefile}; }
