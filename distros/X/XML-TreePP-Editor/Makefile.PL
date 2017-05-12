use 5.005;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::TreePP::Editor',
    AUTHOR              => 'Russell E Glaue',
    VERSION_FROM        => 'lib/XML/TreePP/Editor.pm',
    ABSTRACT_FROM       => 'lib/XML/TreePP/Editor.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM           => {
                             'XML::TreePP' => 0.39,
                             'XML::TreePP::XMLPath' => 0.61,
                             'Data::Dumper' => 2.125,
                             'Test::More' => 0,
                           },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-TreePP-Editor-*' },
);
