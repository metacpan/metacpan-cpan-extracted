use 5.005;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::TreePP::XMLPath',
    AUTHOR              => 'Russell E Glaue',
    VERSION_FROM        => 'lib/XML/TreePP/XMLPath.pm',
    ABSTRACT_FROM       => 'lib/XML/TreePP/XMLPath.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM           => { 'XML::TreePP'  => 0.39,
                             'Data::Dumper' => 2.0,
                           },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-TreePP-XMLPath-*' },
);
