use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME          => 'XML::SAX::SVGTransformer',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/XML/SAX/SVGTransformer.pm',
    ABSTRACT_FROM => 'lib/XML/SAX/SVGTransformer.pm',
    LICENSE       => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/charsbar/XML-SAX-SVGTransformer',
        },
    },
);
