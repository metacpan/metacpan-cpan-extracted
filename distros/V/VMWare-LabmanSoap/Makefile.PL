use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'VMWare::LabmanSoap',
    AUTHOR              => q{David F. Kinder, Jr. <dkinder@davidkinder.net>},
    VERSION_FROM        => 'lib/VMWare/LabmanSoap.pm',
    ABSTRACT_FROM       => 'lib/VMWare/LabmanSoap.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		  'SOAP::Lite' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'VMWare-LabmanSoap-*' },
);

