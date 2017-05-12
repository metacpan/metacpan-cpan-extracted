use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::Constructor',
    AUTHOR              => q{Judioo <judioo@cpan.org>},
    VERSION_FROM        => 'lib/XML/Constructor.pm',
    ABSTRACT_FROM       => 'lib/XML/Constructor.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => 0,
        'XML::LibXML' => 1.60,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Constructor-*' },
);
