use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Authinfo',
    AUTHOR              => q{brad clawsie <bclawsie@cpan.org>},
    VERSION_FROM        => 'lib/Text/Authinfo.pm',
    ABSTRACT_FROM       => 'lib/Text/Authinfo.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More' => 0,
                  'Text::CSV' => 1.21,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Authinfo-*' },
);
