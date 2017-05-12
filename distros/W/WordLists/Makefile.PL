use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WordLists',
    AUTHOR              => q{Daniel Perrett <dperrett@cambridge.org>},
    VERSION_FROM        => 'lib/WordLists/Base.pm',
    ABSTRACT            => 'WordLists - tools for working with lists of words',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES   => {},
    PREREQ_PM  => {
        'JSON' => 0,
        'Test::More' => 0,
        'Test::Deep' => 0,
        'Storable' => 0,
        'Lingua::EN::Tagger' => 0,
        'Unicode::Normalize' => 0,
        'Data::Dumper' => 0,
        'IO::File' => 0,
    },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean     => { FILES => 'WordLists-*' },
	NO_MYMETA =>0
);
