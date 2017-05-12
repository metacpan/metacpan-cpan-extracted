use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# avoid warnings in version number comparsion when version number
# contains an underscore
no warnings 'numeric';

WriteMakefile(
    NAME                => 'Text::BlockLayout',
    AUTHOR              => q{Moritz Lenz <moritz@cpan.org>},
    VERSION_FROM        => 'lib/Text/BlockLayout.pm',
    ABSTRACT_FROM       => 'lib/Text/BlockLayout.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Text::Wrapper' => 0,
        Moo             => 0.091011,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-BlockLayout-*' },
);
