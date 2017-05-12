use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Pangram',
    AUTHOR              => q{Jesse Sheidlower <jester@panix.com>},
    VERSION_FROM        => 'lib/Text/Pangram.pm',
    ABSTRACT_FROM       => 'lib/Text/Pangram.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'List::MoreUtils' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Pangram-*' },
);
