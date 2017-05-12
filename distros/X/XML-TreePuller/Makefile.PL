use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::TreePuller',
    AUTHOR              => q{Tyler Riddle <triddle@gmail.com>},
    VERSION_FROM        => 'lib/XML/TreePuller.pm',
    ABSTRACT_FROM       => 'lib/XML/TreePuller.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::LibXML' => 1.70,
        'XML::CompactTree' => 0.03,
        'Tree::XPathEngine' => 0.05,
        'Scalar::Util' => 1.23,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-TreePuller-*' },
);
