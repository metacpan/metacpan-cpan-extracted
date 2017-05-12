use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::Tiny::Simple',
    AUTHOR              => q{Nicolas Georges <xlat@cpan.org>},
    VERSION_FROM        => 'lib/XML/Tiny/Simple.pm',
    ABSTRACT_FROM       => 'lib/XML/Tiny/Simple.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::Tiny' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-Tiny-Simple-*' },
);
