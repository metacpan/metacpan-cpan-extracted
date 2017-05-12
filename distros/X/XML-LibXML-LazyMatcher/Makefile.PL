use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::LibXML::LazyMatcher',
    AUTHOR              => q{Toru Hisai <toru@torus.jp>},
    VERSION_FROM        => 'lib/XML/LibXML/LazyMatcher.pm',
    ABSTRACT_FROM       => 'lib/XML/LibXML/LazyMatcher.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'XML::LibXML' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-LibXML-LazyMatcher-*' },
);
